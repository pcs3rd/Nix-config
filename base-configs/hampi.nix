{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

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
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  environment.systemPackages = with pkgs; [
    nano
    git 
  ];

  nix.settings.trusted-users = [ "root" ];
  services.openssh.enable = true;

  users.mutableUsers = true;
  users.users = {
    operator = {
      isNormalUser = true;
      home = "/home/operator";
      description  = "HamPi Operator";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      password = "";
    };
  };
  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  
  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/NIXOS_SD"; # this is important!
      fsType = "ext4";
      options = [ "noatime" ];
    };
  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;

  # Needed for rebuilding on the Pi. You might not need this with more
  #memory, but my Pi only has 1GB.
  swapDevices = [{
    device = "/swapfile";
    size = 4048;
  }];

  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;

  services.xserver.desktopManager.phosh.enable = true;
  services.xserver.desktopManager.phosh.user = "operator";
  services.xserver.desktopManager.phosh.group = "100";
  nixpkgs.buildPlatform = builtins.currentSystem;
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

}

