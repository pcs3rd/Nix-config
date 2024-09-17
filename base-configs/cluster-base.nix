{ inputs, outputs, lib, pkgs, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModule.disko
    ];

  disko.devices.disk.NixOS.device = "/dev/sda1";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.blade-worker = {
    isNormalUser  = true;
    home  = "/home/blade-worker";
    description  = "";
    uid = 1000;
    extraGroups  = [ "networkmanager" ];
    hashedPasswordFile = "/stateful/sys-data/worker-passwordHash"; #  mkpasswd -m sha-512 
  };

  services.openssh.enable = true;
  system.stateVersion = "24.05";

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}