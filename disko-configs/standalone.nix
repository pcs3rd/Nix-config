{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModules.disko
    ];
  disko.devices = {
    disk = {
       NixOS = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
                priority = 1;
                name = "ESP";
                start = "1";
                end = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
            };
            NixOS = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                subvolumes = {
                  "/stateful" = {
                      mountOptions = [ "compress=zstd" ];
                      mountpoint = "/stateful";
                  };
                  "/nix-store" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "/docker" = {
                      mountOptions = [ "compress=ztd" "noatime" ];
                      mountpoint = "/var/lib/docker";
                  };
                };
              };
            };
          };
        };
      };
    };
    nodev = {
      "/" = {
          fsType = "tmpfs";
          mountOptions = [
              "size = 1G"
          ];
      };
    };
  };
# Save some needed stuff
  fileSystems."/stateful".neededForBoot = true;
  environment.persistence."/stateful" = {
    enable = true; 
    hideMounts = true;
    directories = [
        "/var/log"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
    ];
  };
}
