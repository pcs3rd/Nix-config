{ config, pkgs, inputs, output, ... }:

{
users.users.rdean = {
  isNormalUser = true;
  home  = "/home/rdean";
  description  = "Raymond Dean III";
  extraGroups  = [ "wheel" "networkmanager" ];
};

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  xresources.properties = {
    "Xcursor.size" = 16;
    "Xft.dpi" = 172;
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