{ config, pkgs, inputs, output, ... }:

{
users.users.rdean = {
  isNormalUser = true;
  home  = "/home/rdean";
  description  = "Raymond Dean III";
  extraGroups  = [ "wheel" "networkmanager" ];
  hashedPasswordFile = "/stateful/sys-data/rdean-passwordHash"; #  mkpasswd -m sha-512 
};
  home-manager.users.rdean = {
    home.homeDirectory = "/home/rdean";
    home.packages = with pkgs; [
      nnn # terminal file manager
      # misc
      cowsay
      file
      which
      tree
      gnused
      gnutar
      gawk
      zstd
      gnupg
      nix-output-monitor
      btop  # replacement of htop/nmon
      iotop # io monitoring
      iftop # network monitoring
      strace # system call monitoring
      ltrace # library call monitoring
      lsof # list open files
      sysstat
      lm_sensors # for `sensors` command
      ethtool
      pciutils # lspci
      usbutils # lsusb
      tmux
      alacritty
      htop 
    ];
    home.stateVersion = "24.05";

  };
}