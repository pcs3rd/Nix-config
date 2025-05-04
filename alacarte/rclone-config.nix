{ inputs, outputs, lib, pkgs, ... }:{
    fileSystems."/Disks/Jellyfin/80b6" = {
    device = "sevenofnine:/Disks/Jellyfin/80b6";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "args2env"
        "config=/stateful/sys-data/rclone-mnt.conf"
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
        "config=/stateful/sys-data/rclone-mnt.conf"
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
        "config=/stateful/sys-data/rclone-mnt.conf"
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
        "config=/stateful/sys-data/rclone-mnt.conf"
    ];
    };
}


