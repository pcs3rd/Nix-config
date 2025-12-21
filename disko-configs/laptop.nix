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
                  "/etc" = {
                      mountOptions = [ "compress=zstd" "noexec" ];
                      mountpoint = "/etc";
                  };
                  "/stateful" = {
                      mountOptions = [ "compress=zstd" "noexec" ];
                      mountpoint = "/stateful";
                  };
                  "/nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "/home" = {
                      mountOptions = [ "compress=zstd" "noatime" "noexec" ];
                      mountpoint = "/home";
                  };
                };
              };
            };
            Swap = {
              size = "4G";
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
        "size=512M"
        "defaults"
        "mode=755"
      ];
    };
    nodev."/tmp" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=512M"
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
        "/var/lib/nixos"
        "/var/lib/tailscale/"
    ];
  };
}
