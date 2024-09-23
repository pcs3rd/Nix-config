{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    git
    nano
    tmux
    htop
    glusterfs
    nano
    mtm
    smartmontools
    browsh
  ];
  i18n.defaultLocale = "en_US.UTF-8";
  environment.variables = {
    "EDITOR" = "nano";
  };
  documentation.enable = false; # documentation of packages
  documentation.nixos.enable = false; # nixos documentation
  documentation.man.enable = false; # manual pages and the man command
  documentation.info.enable = false; # info pages and the info command
  documentation.doc.enable = false; # documentation distributed in packages' /share/doc
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  services.devmon.enable = true; # I want to auto-mount disks.
  services.gvfs.enable = true; 
  services.udisks2.enable = true;
  users.motd = "UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED

You must have explicit, authorized permission to access or configure this device. Unauthorized attempts and actions to access or use this system may result in civil and/or criminal penalties. All activities performed on this device are logged and monitored.";
}