
{ hostname, username, ... }:

#############################################################
#
#  Host & Users configuration
#
#############################################################

{
  networking.hostName = "raymonds-macbook-air";
  networking.computerName = "raymonds-macbook-air";
  system.defaults.smb.NetBIOSName = "raymonds-macbook-air";

  users.users."rdean3"= {
    home = "/Users/rdean3";
    description = "rdean3";
  };

  nix.settings.trusted-users = [ "rdean3" ];
}