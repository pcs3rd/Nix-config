{ ... }: {


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

}