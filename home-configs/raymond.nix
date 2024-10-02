{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
  imports = [ 
    inputs.home-manager.nixosModules.home-manager
    ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  users.users.rdean = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  home-manager.users.rdean = {
    home.packages = with pkgs; [
      tmux
      htopvscode
      git
      nano
      carla
    ];
    home.stateVersion = "24.05";

  };
  sound.enable = true;  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
}

