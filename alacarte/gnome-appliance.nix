
{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
# I do not care about security for this device it sits in the car, with no internet access, and will only do ham radio.
services.mingetty.autologinUser = "operator";
    # Some more help text.
    services.mingetty.helpLine =
      ''
        Property of Raymond Dean, KC3ZXI. 
        This device is immutable. Changes will not persist reboots.
      '';

services.displayManager.autoLogin.enable = true;
services.displayManager.autoLogin.user = operator;
  users.users = {
    operator = {
      isNormalUser = true;
      home = "/home/operator";
      description  = "manager user for ssh access";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/manager-passwordHash"; #  mkpasswd -m sha-512 
    };
  };
}
