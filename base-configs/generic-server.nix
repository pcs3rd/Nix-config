{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Network
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  time.timeZone = "America/New_York";

# User stuff
  users.users = {
      admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/admin-passwordHash"; #  mkpasswd -m sha-512 
    };
    manager = {
      isNormalUser  = true;
      home = "/home/manager";
      description  = "";
      uid = 1000;
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/manager-passwordHash"; #  mkpasswd -m sha-512 
    };
  }
# Servicses
  services.openssh.enable = true;
  system.stateVersion = "24.05";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}