# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:{


# Network
  networking.networkmanager.enable = true;
  networking.firewall.enable = false;
  time.timeZone = "America/New_York";

# User stuff
  users.users.admin = {
    isNormalUser  = true;
     isNormalUser = true;
     extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
     hashedPasswordFile = "/stateful/sys-data/worker-passwordHash"; #  mkpasswd -m sha-512 
  };

# Environment
  i18n.defaultLocale = "en_US.UTF-8";
  environment.variables = {
    "EDITOR" = "nano";
  };
  environment.systemPackages = with pkgs; [
    nano
    mtm
    smartmontools
  ];

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