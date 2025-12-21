{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];
  systemd.enableEmergencyMode = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = "$y$j9T$6GwTquCtnA..a0Q3twb5q.$KfIKAmpzRIpg28AFswEF41TPpqmmGPjO8poC7sPNIK4";
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  security.polkit.enable = true;
	security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
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

  boot.initrd.availableKernelModules = [ "xhci_pci" "sdhci_pci" "usb_storage" "sd_mod" ];  
  boot.initrd.kernelModules = [];
  boot.kernelModules = [ "kvm-intel" ];
}

