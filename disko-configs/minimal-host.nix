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
      { file = "/etc/hostname"; parentDirectory = { mode = "u=r,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_rsa_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
      { file = "/etc/ssh/ssh_host_ed25519_key.pub"; parentDirectory = { mode = "u=rwx,g=r,o=r"; }; }
    ];
  };

# ISCSI Stuff
   boot.kernelModules = [ "iscsi_tcp" ]; 

   services.openiscsi = {
    enable = true;  # Enable openiscsi daemon
    name = "iqn.2024-09.com.nixos:my-nixos-initiator"; 

    discoverPortal = "10.0.0.3";   # IP of your iscsi server
  };

  systemd.services.iscsi-login-lingames = {
    description = "Init connection to storage backplane";
    after = [ "network.target" "iscsid.service" ];
    wants = [ "iscsid.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.openiscsi}/bin/iscsiadm -m discovery -t sendtargets -p 10.0.0.3";
      ExecStart = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:lingames -p 10.0.0.3 --login";
      ExecStop = "${pkgs.openiscsi}/bin/iscsiadm -m node -T iqn.2005-10.org.freenas.ctl:lingames -p 10.0.0.3 --logout";
      Restart = "on-failure";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
  };

}
