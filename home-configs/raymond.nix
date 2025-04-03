{ config, pkgs, inputs, output, ... }:

{
users.users.rdean = {
  isNormalUser = true;
  home  = "/home/rdean";
  description  = "Raymond Dean III";
  extraGroups  = [ "wheel" "networkmanager" "dialout" "feedbackd" "networkmanager" "video" ];
  hashedPasswordFile = "/stateful/sys-data/rdean-passwordHash"; #  mkpasswd -m sha-512 
};
  home-manager.users.rdean = {
    home.homeDirectory = "/home/rdean";
    home.packages = with pkgs; [
      tmux
      htop 
    ];
    home.stateVersion = "24.05";

  };
}
