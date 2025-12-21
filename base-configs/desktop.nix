{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];



  systemd.enableEmergencyMode = true;
  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.availableKernelModules = [ "xhci_pci" "sdhci_pci" "usb_storage" "sd_mod" ];  
  boot.initrd.kernelModules = [];
  boot.kernelModules = [ "kvm-intel" ];

  security.polkit.enable = true;
	security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = true;

  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
  };

  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
 
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [ 
    git 
    tmux
  ];
  users.users = {
    rdean3 = {
      isNormalUser = true;
      home = "/home/rdean3";
      description  = "Raymond Dean III";
      uid = 1000; 
      extraGroups = [ "wheel" "networkmanager" "storage" ]; 
    };
  };
}

