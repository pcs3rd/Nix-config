{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
    ];
  boot.initrd.availableKernelModules = [ "btrfs" ];
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
                size = "512M";
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
                    "/user_data" = {
                        mountOptions = [ "compress=zstd" "noexec" ];
                        mountpoint = "/home";
                    };
                    "/system_data" = {
                        mountOptions = [ "compress=zstd" "noexec" ];
                        mountpoint = "/stateful";
                    };
                    "/nix" = {
                        mountOptions = [ "compress=zstd" "noatime" ];
                        mountpoint = "/nix";
                    };
                    "/docker" = {
                        mountOptions = [ "compress=zstd" "noatime" ];
                        mountpoint = "/var/lib/docker";
                    };
                    };
                };
            };
          };
        };
      };
    };
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=512M"
        "defaults"
        "mode=755"
      ];
    };
  };
  fileSystems."/system_data".neededForBoot = true;
  fileSystems."/nix".neededForBoot = true;
  fileSystems."/docker".neededForBoot = true;

  environment.persistence."/stateful" = {
    enable = true; 
    hideMounts = true;
    directories = [
        "/var/log"
        "/root/.ssh"
        "/var/lib/nixos"
        "/var/lib/tailscale/"
        "/var/lib/systemd/coredump"
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
