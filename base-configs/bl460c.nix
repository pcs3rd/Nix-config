{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Network
  networking.networkmanager.enable = true;
  networking = {
    vlans = {
      vlan2 = {id=2; interface="enp2s0f1"; }; # these hosts show up all willy-nilly on my unifi console. This might fix it
    };
  };


  time.timeZone = "America/New_York";
  networking.timeServers = options.networking.timeServers.default ++ [ "time.google.com" ]; 


# User stuff
  users.users = {
    manager = {
      isNormalUser = true;
      home = "/home/manager";
      description  = "manager user for ssh access";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/manager-passwordHash"; #  mkpasswd -m sha-512 
    };
  };
  system.stateVersion = "24.05";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "be2iscsi" "hpsa" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

# Rclone config for appdata storage

  #Make sure rclone is there  
  environment.systemPackages = [ pkgs.rclone ];
  
  fileSystems."/persist/dev" = {
    device = "AppData:/persist/dev"; # force correct path
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/stateful/sys-data/rclone-mnt.conf"
      "uid=911" 
      "gid=911" 
    ];
  };
  fileSystems."/persist/downloads" = {
    device = "AppData:/persist/downloads";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/stateful/sys-data/rclone-mnt.conf"
      "uid=911" 
      "gid=911" 
    ];
  };
  fileSystems."/persist/remote-downloads" = {
    device = "seedbox:/downloads/manual";
    fsType = "rclone";
    options = [
      "nodev"
      "nofail"
      "allow_other"
      "args2env"
      "config=/stateful/sys-data/rclone-mnt.conf"
      "uid=911" 
      "gid=911" 
    ];
  };

}
