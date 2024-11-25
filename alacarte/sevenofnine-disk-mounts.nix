{ pkgs, ... }: {
  fileSystems."/Disks/Jellyfin/80b6" = # Media
    { device = "/dev/disk/by-uuid/80b68e30-d9d5-454a-abec-11f7c0c70e58";
      fsType = "ext4";
    };

  fileSystems."/Disks/Jellyfin/242b" = # Media
    { device = "/dev/disk/by-uuid/242b9249-f2d0-4f81-93d5-54919f03cf3e";
      fsType = "ext4";
    };
   fileSystems."/Disks/Jellyfin/2111" =
      { device = "/dev/disk/by-uuid/2111d93a-159d-4a2c-8fc5-24b93026e254";
        fsType = "btrfs";
        options = [ "subvol=media" ];
      };
  fileSystems."/persist" = #appdata and crap
    { device = "/dev/disk/by-uuid/fdb0778a-4425-4fc1-9bc9-e9e1fd1550ec";
      fsType = "btrfs";
      options = [ "subvol=AppData" "compress=zstd" ];
    };


  #Make sure rclone is there  
  environment.systemPackages = [ pkgs.rclone ];

#  fileSystems."/persist/remote-downloads" = { #This is not in use anymore, but am keeping for future reference.
#    device = "seedbox:/downloads/manual";
#    fsType = "rclone";
#    options = [
#      "nodev"
#      "nofail"
#      "allow_other"
#      "args2env"
#      "config=/stateful/sys-data/rclone-mnt.conf"
#      "uid=911" 
#      "gid=911" 
#    ];
#  };
}
