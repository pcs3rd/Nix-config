{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
    ];
  disko.devices = {
    disk = {
       system = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            esp = {
                priority = 1;
                name = "esp";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
            };
            user = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                subvolumes = {
                  "/stateful" = {
                      mountOptions = [ "compress=zstd" "noexec" ];
                      mountpoint = "/stateful";
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  # User data: compressed, normal copy-on-write.
                  "/home" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/home";
                  };
                  # Steam library: no compression (game assets are already
                  # compressed, so zstd just burns CPU) and nodatacow (games
                  # write/patch large files often; COW fragments them badly
                  # over time, and this is also the standard recommendation
                  # for Proton prefixes under steamapps/compatdata). Trade-off:
                  # no checksumming on this subvolume.
                  #
                  # Mounted at Steam's actual default library path, so
                  # installed games land here with no manual "Add Library
                  # Folder" step in Steam.
                  "/games" = {
                    mountOptions = [ "noatime" "nodatacow" "compress=no" ];
                    mountpoint = "/home/steamos/.local/share/Steam/steamapps";
                  };
                };
              };
            };
            Swap = {
              size = "8G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true; # resume from hiberation from this device
              };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=1G"
        "defaults"
        "mode=755"
      ];
    };
  };
  fileSystems."/stateful".neededForBoot = true;
  environment.persistence."/stateful" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/root/.ssh"
      "/var/lib/nixos"
      "/var/lib/tailscale/"
      "/var/lib/systemd/coredump"
      "/var/lib/decky-loader"    # Decky plugin loader state/plugins
      "/var/lib/bluetooth"       # controller pairings
      "/var/lib/NetworkManager"  # DHCP leases, seen networks (beyond saved profiles below)
      "/etc/NetworkManager/system-connections"
    ];
    files = [
      { file = "/etc/machine-id"; parentDirectory = { mode = "u=rwx,g=rwx,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
    ];
  };
}
