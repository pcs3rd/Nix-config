{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{

  services = {
    xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
    };
    displayManager.defaultSession = "xfce";
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
      password = "";
    };
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

}

