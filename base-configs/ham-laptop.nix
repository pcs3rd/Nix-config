{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{

  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm.enable = true;
    displayManager.sddm.wayland.enable = true;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "operator";
  };

  users.users = {
    operator = {
      isNormalUser = true;
      home = "/home/operator";
      description  = "operator user";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/operator-passwordHash"; #  mkpasswd -m sha-512 
    };
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

}

