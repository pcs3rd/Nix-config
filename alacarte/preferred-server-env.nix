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
  ];
  i18n.defaultLocale = "en_US.UTF-8";
  environment.variables = {
    "EDITOR" = "nano";
  };
  boot.loader.systemd-boot.enable = true
  documentation.enable = false; # documentation of packages
  documentation.nixos.enable = false; # nixos documentation
  documentation.man.enable = false; # manual pages and the man command
  documentation.info.enable = false; # info pages and the info command
  documentation.doc.enable = false; # documentation distributed in packages' /share/doc
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
}