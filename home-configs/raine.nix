{ config, pkgs, inputs, output, ... }:

{
programs.dconf.enable = true;
users.users.rdean = {
  isNormalUser = true;
  home  = "/home/rdean";
  description  = "Raine";
  extraGroups  = [ "wheel" "networkmanager" "dialout" "feedbackd" "networkmanager" "video" "i2c" ];
  hashedPasswordFile = "/stateful/sys-data/rdean-passwordHash"; #  mkpasswd -m sha-512 
};
  home-manager.users.rdean = {

    dconf = {
      settings = {
        "org/gnome/desktop/peripherals/mouse" = {
          natural-scroll = true;
          speed = 0.0; # -1.0 to 1.0
        };
      };
    };
    home.homeDirectory = "/home/rdean";
    home.packages = with pkgs; [
      tmux
      htop 
      vial
      google-chrome
      firefox
      python313Packages.meshtastic
      vscode
      moonlight
      discord
    ];
    home.stateVersion = "25.11";

  };
  services.udev.packages = [ pkgs.via pkgs.vial ];

}
