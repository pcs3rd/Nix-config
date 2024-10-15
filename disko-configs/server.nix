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
        "size=1G"
        "defaults"
        "mode=755"
      ];
    };
    nodev."/home" = {
      fsType = "tmpfs";
      mountOptions = [
        "size=1G"
        "defaults"
        "mode=666"
        "noexec"
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
        "/var/lib/systemd/coredump"
        "/etc/NetworkManager/system-connections"
        { directory = "/home/manager/.config"; user = "manager"; group = "1000"; mode = "u=rwx,g=rx,o=r"; }
        { directory = "/home/manager/.cache"; user = "manager"; group = "1000"; mode = "u=rwx,g=rx,o=r"; }
        { directory = "/home/manager/.ssh"; user = "manager"; group = "1000"; mode = "u=rwx,g=rx,o=r"; }
        { directory = "/home/manager/docker-compose"; user = "manager"; group = "1000"; mode = "u=rwx,g=rx,o=r"; }
        { directory = "/home/manager/scratchpad"; user = "manager"; group = "1000"; mode = "u=rwx,g=rx,o=r"; }
    ];
    files = [
      { file = "/etc/machine-id"; parentDirectory = { mode = "u=rwx,g=rwx,o=r"; }; }
      #{ file = "/home/manager/.bash_history"; parentDirectory = { mode = "u=rwx,g=rwx,o=r"; }; }
      "/home/manager/.gitconfig"
      "/home/manager/.bash_history"
      { file = "/home/manager/.gitconfig"; parentDirectory = { mode = "u=rwx,g=rwx,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
    ];
  };
}
