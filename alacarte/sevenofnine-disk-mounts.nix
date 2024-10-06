{ pkgs, ... }: {
  fileSystems."/Disks/Jellyfin/80b6" =
    { device = "/dev/disk/by-uuid/80b68e30-d9d5-454a-abec-11f7c0c70e58";
      fsType = "ext4";
    };

  fileSystems."/Disks/Jellyfin/242b" =
    { device = "/dev/disk/by-uuid/242b9249-f2d0-4f81-93d5-54919f03cf3e";
      fsType = "ext4";
    };

  fileSystems."/persist" =
    { device = "/dev/disk/by-uuid/fdb0778a-4425-4fc1-9bc9-e9e1fd1550ec";
      fsType = "btrfs";
      options = [ "subvol=AppData" "compress=zstd" ];
    };
  fileSystems."/persist/prod/web/ownfoil/games" =
    { device = "/dev/disk/by-uuid/ac48b9f0-f25c-4d04-bd43-b50d45cdd101";
      fsType = "btrfs";
      options = [ "subvol=games" "compress=zstd" ];
    };

  #Make sure rclone is there  
  environment.systemPackages = [ pkgs.rclone ];

  fileSystems."/persist/remote-downloads" = {
    device = "seedbox:/downloads";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/stateful/sys-data/rclone-mnt.conf"
      "uid=1000" 
      "gid=1000" 
    ];
  };
}
