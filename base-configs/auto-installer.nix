# Generic unattended auto-install image module — usable for ANY host in
# nixosConfigurations, not just one machine. `hostname` and `diskDevice` are
# supplied per-build by mkAutoInstallIso in flake.nix, which reads them
# straight out of that host's own already-defined config.
#
# Build with: nix build .#packages.<system>.<hostname>-installer-iso
# Flash result/iso/*.iso to a USB stick (e.g. `sudo dd if=result/iso/*.iso
# of=/dev/diskN bs=4M status=progress conv=fsync`), boot the target machine
# from it, and walk away.
#
# On boot this partitions `diskDevice` via disko and installs the
# `hostname` flake configuration with no keyboard/mouse interaction
# required, after a 15-second window to abort (power off) in case the wrong
# disk/machine is about to get wiped. Progress is shown as an ncurses
# (whiptail) gauge on the physical console. Network access is still required
# during install for fetching packages from the NixOS binary cache — this
# is not a fully offline/airgapped installer.
{ config, lib, pkgs, inputs, outputs, self, hostname, diskDevice, modulesPath, ... }:
{
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Embed this exact revision of the flake in the ISO so the install script
  # doesn't need to fetch it over the network at boot.
  environment.etc."nix-config".source = self;

  environment.systemPackages = [
    pkgs.git
    pkgs.parted
    pkgs.newt # whiptail, for the ncurses progress gauge
    # disko's CLI, baked into the image so partitioning doesn't depend on
    # being able to resolve github: at boot.
    inputs.disko.packages.${pkgs.system}.default
  ];

  systemd.services.auto-install = {
    description = "Unattended install of ${hostname}";
    wantedBy = [ "multi-user.target" ];
    after = [ "getty@tty1.service" "systemd-user-sessions.service" ];
    conflicts = [ "getty@tty1.service" ];
    # disko (partitioning) and nixos-install both need root.
    environment.TERM = "linux"; # whiptail needs this to draw on the raw console
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";
      StandardInput = "tty";
      StandardOutput = "tty";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVTDisallocate = true;
    };
    script = ''
      set -euo pipefail

      WT_TITLE="${hostname} installer"

      # Persistent ncurses gauge, fed via a FIFO for the whole install run.
      fifo=$(mktemp -u)
      mkfifo "$fifo"
      exec 3<> "$fifo"
      rm -f "$fifo"
      whiptail --title "$WT_TITLE" --gauge "Starting..." 10 70 0 <&3 &
      wt_pid=$!

      cleanup() {
        exec 3>&- 2>/dev/null || true
        kill "$wt_pid" 2>/dev/null || true
      }
      trap cleanup EXIT

      # progress <percent> <message>
      progress() {
        printf 'XXX\n%d\n%s\nXXX\n' "$1" "$2" >&3
      }

      for i in $(seq 1 15); do
        remaining=$((15 - i))
        progress "$i" "Target disk: ${diskDevice}\n\nTHIS DISK WILL BE COMPLETELY ERASED.\nPower off now to abort.\n\nInstalling in ''${remaining}s..."
        sleep 1
      done

      progress 20 "Partitioning ${diskDevice} with disko..."
      disko --mode disko --flake /etc/nix-config#${hostname}

      progress 50 "Installing NixOS (needs network access)..."
      nixos-install --root /mnt --no-root-passwd --flake /etc/nix-config#${hostname}

      progress 100 "Install complete.\n\nRebooting in 10 seconds — remove the USB drive."
      sleep 10

      cleanup
      trap - EXIT
      reboot
    '';
  };
}
