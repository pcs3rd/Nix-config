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

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "mmc_block" "sdhci_acpi" ];  
  boot.initrd.kernelModules = [ "mmc_block" "sdhci_acpi" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];
}

