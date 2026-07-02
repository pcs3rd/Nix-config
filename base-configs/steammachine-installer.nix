# Live installer image for the steammachine host. Build with:
#   nix build .#steammachine-installer-iso
# Flash result/iso/*.iso to a USB stick (e.g. `sudo dd if=result/iso/*.iso
# of=/dev/diskN bs=4M status=progress conv=fsync`), boot the target machine
# from it, and walk away.
#
# On boot this partitions /dev/sda via disko and installs the "steammachine"
# flake configuration with no keyboard/mouse interaction required, after a
# 15-second window to abort (power off) in case the wrong disk/machine is
# about to get wiped. Network access is still required during install for
# fetching packages from the NixOS binary cache — this is not a fully
# offline/airgapped installer.
{ config, lib, pkgs, inputs, outputs, self, modulesPath, ... }:
{
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Embed this exact revision of the flake in the ISO so the install script
  # doesn't need to fetch it over the network at boot.
  environment.etc."nix-config".source = self;

  environment.systemPackages = [
    pkgs.git
    pkgs.parted
    # disko's CLI, baked into the image so partitioning doesn't depend on
    # being able to resolve github: at boot.
    inputs.disko.packages.${pkgs.system}.default
  ];

  systemd.services.steammachine-auto-install = {
    description = "Unattended steammachine install";
    wantedBy = [ "multi-user.target" ];
    after = [ "getty@tty1.service" "systemd-user-sessions.service" ];
    conflicts = [ "getty@tty1.service" ];
    serviceConfig = {
      Type = "oneshot";
      StandardInput = "tty";
      StandardOutput = "tty";
      TTYPath = "/dev/tty1";
      TTYReset = true;
      TTYVTDisallocate = true;
    };
    script = ''
      set -euo pipefail
      DISK=/dev/sda

      echo "=================================================="
      echo " steammachine unattended installer"
      echo " Target disk: $DISK — THIS DISK WILL BE COMPLETELY ERASED"
      echo " Power off now to abort. Installing in:"
      echo "=================================================="
      for i in $(seq 15 -1 1); do printf "\r  %2ds... " "$i"; sleep 1; done
      echo

      echo "[1/2] Partitioning $DISK with disko..."
      disko --mode disko --flake /etc/nix-config#steammachine

      echo "[2/2] Installing NixOS (this needs network access)..."
      nixos-install --root /mnt --no-root-passwd --flake /etc/nix-config#steammachine

      echo "=================================================="
      echo " Install complete. Rebooting in 10 seconds — remove the USB drive."
      echo "=================================================="
      sleep 10
      reboot
    '';
  };
}
