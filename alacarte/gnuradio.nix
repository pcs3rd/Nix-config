{ inputs, outputs, lib, pkgs, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.bash
        pkgs.git
        pkgs.nix
        pkgs.browsh
        pkgs.firefox
        pkgs.systemctl-tui
        pkgs.hamlib
        pkgs.hamtransfer
        pkgs.tlf
        pkgs.soundmodem
        pkgs.grig
        pkgs.wsjtx
        pkgs.gpredict
        pkgs.gqrx
        pkgs.gnuradio
    ];
  documentation.enable = false; # documentation of packages
  documentation.nixos.enable = false; # nixos documentation
  documentation.man.enable = false; # manual pages and the man command
  documentation.info.enable = false; # info pages and the info command
  documentation.doc.enable = false; # documentation distributed in packages' /share/doc
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
}