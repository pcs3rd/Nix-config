{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
# Network
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

  # Enable QEMU/KVM guest agent
  services.qemuGuest.enable = true;
  
  # Enable SPICE guest agent
  services.spice-vdagentd.enable = true; 
# Network adapt for nfs
  networking = {
    interfaces.enp5s0 = {
      ipv4.addresses = [{
        address = "192.168.100.10";
        prefixLength = 24;
      }];
    };
    defaultGateway = {
      address = "192.168.100.1";
      interface = "ens3";
    };

  };
# User stuff
  users.users = {

    manager = {
      isNormalUser = true;
      home = "/home/manager";
      description  = "General Manager User";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/manager-passwordHash"; #  mkpasswd -m sha-512 
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Set the mount point to your EFI partition, usually /boot or /boot/efi
  boot.loader.efi.efiSysMountPoint = "/boot"; 

  # Ensure GRUB is disabled
  boot.loader.grub.enable = false;

  system.stateVersion = "24.05";
  boot.initrd.availableKernelModules = [ "ehci_pci" "uhci_hcd" "ahci" "sr_mod" "xen_blkfront" "virtio_blk" "virtio_pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
