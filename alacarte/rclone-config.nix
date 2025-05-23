{ inputs, outputs, lib, pkgs, ... }:{
    environment.systemPackages = [ pkgs.rclone ];
    fileSystems."/Disks/Jellyfin/80b6" = {
    device = "sevenofnine:/Disks/Jellyfin/80b6";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "allow_other"
        "gid=911"
        "uid=911"
        "args2env"
        "x-systemd.automount"
        "x-systemd.mount-timeout=86400s"
        "x-systemd.after=network-online.target"
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
        "gid=911"
        "uid=911"
        "x-systemd.automount"
        "x-systemd.mount-timeout=86400s"
        "x-systemd.after=network-online.target"
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
        "gid=911"
        "uid=911"
        "x-systemd.automount"
        "x-systemd.mount-timeout=86400s"
        "x-systemd.after=network-online.target"
        "config=/stateful/sys-data/rclone-mnt.conf"
    ];
    };
    fileSystems."/persist" = {
    device = "sevenofnine:/persist";
    fsType = "rclone";
    options = [
        "nodev"
        "nofail"
        "gid=911"
        "uid=911"
        "allow_other"
        "umask=750"
        "args2env"
        "x-systemd.automount"
        "x-systemd.mount-timeout=86400s"
        "x-systemd.after=network-online.target"
        "config=/stateful/sys-data/rclone-mnt.conf"
    ];
    };

}


