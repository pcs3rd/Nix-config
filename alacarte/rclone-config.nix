{ inputs, outputs, lib, pkgs, ... }:{
    fileSystems."/Disks/Jellyfin/80b6" = {
    device = "sevenofnine:/Disks/Jellyfin/80b6";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
    ];
    };
    fileSystems."/Disks/Jellyfin/242b" = {
    device = "sevenofnine:/Disks/Jellyfin/242b";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
    ];
    };
    fileSystems."/Disks/Jellyfin/2111" = {
    device = "sevenofnine:/Disks/Jellyfin/2111";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
    ];
    };
    fileSystems."/persist" = {
    device = "sevenofnine:/persist";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/etc/rclone-mnt.conf"
    ];
    };
}




  fileSystems."/persist" = #appdata and crap
    { device = "/dev/disk/by-uuid/fdb0778a-4425-4fc1-9bc9-e9e1fd1550ec";
      fsType = "btrfs";
      options = [ "subvol=AppData" "compress=zstd" ];
    };
