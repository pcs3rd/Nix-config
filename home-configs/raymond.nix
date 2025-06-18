{ config, pkgs, inputs, output, ... }:

{
users.users.rdean = {
  isNormalUser = true;
  home  = "/home/rdean3";
  description  = "Raymond Dean III";
  extraGroups  = [ "wheel" "networkmanager" "dialout" "feedbackd" "networkmanager" "video" ];
  hashedPasswordFile = "/stateful/sys-data/rdean-passwordHash"; #  mkpasswd -m sha-512 
};
  home-manager.users.rdean = {
    home.homeDirectory = "/home/rdean3";
    home.packages = with pkgs; [
      tmux
      htop 
      python313Packages.meshtastic
    ];
    home.stateVersion = "25.05";

  };
}
