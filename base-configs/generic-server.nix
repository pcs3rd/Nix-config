{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Network
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

# User stuff
  users.users = {
    drone = {
      isNormalUser = true;
      home = "/home/drone;
      description  = "Borg Drone";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPassword = "$6$XtwzZCyEqwDktY5s$5wPBboaEoGRWcmyMqTZiYAhIhdTFchislGlCtchSSfw3fvsdUloEy8tTbqOdW.LkmPf5Kbq0dRtC5QzqcIGyv/"; #  mkpasswd -m sha-512 
    };
  };
  system.stateVersion = "26.05";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "be2iscsi" "hpsa" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
