{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];
  boot = {
    plymouth = {
      enable = true;
      theme = "rings";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "rings" ];
        })
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;

  };
  environment.systemPackages = with pkgs; [ 
    git 
    tmux
  ];
  systemd.enableEmergencyMode = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = "$y$j9T$6GwTquCtnA..a0Q3twb5q.$KfIKAmpzRIpg28AFswEF41TPpqmmGPjO8poC7sPNIK4";
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

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
      extraGroups = [ "wheel" "networkmanager" "storage" ]; 
      password = "$y$j9T$0ZiFCQ2dn.zGxVX62JfZo.$dnftReWlS2qlqTg7ByAKSDt0ZSPv.CZjsCZp5F8tTn0";
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

