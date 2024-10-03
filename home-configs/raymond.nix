{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [ 
    ];
  home = {
    username = "rdean";
    homeDirectory = "/home/rdean";
  };
    home.packages = with pkgs; [
      tmux
      htopvscode
      git
      nano
      carla
    ];
  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05";
}

