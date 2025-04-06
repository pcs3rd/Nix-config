{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

# Network
  networking.networkmanager.enable = true;
  boot.kernel.sysctl = {
    # Enable IPv4 forwarding
    "net.ipv4.conf.all.forwarding" = true;

    # Disable IPv6 Forwarding
    "net.ipv6.conf.all.forwarding" = false;

    # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
    # By default, not automatically configure any IPv6 addresses.
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.autoconf" = 0;
    "net.ipv6.conf.all.use_tempaddr" = 0;

    # On WAN, allow IPv6 autoconfiguration and tempory address use.
    "net.ipv6.conf.${name}.accept_ra" = 2;
    "net.ipv6.conf.${name}.autoconf" = 1;
  };

  # Enable Bind for local DNS Resolving
  services.bind.enable = true;
  networking = {
    useDHCP = false;
    hostName = "router";
    nameserver = [ "<DNS IP>" ];
    # Define VLANS
    vlans = {
      upstream = {
        id = 10;
        interface = "enp1s0";
      };
      clusterBackplane = {
        id = 20;
        interface = "enp2s0";
      };
    };

    interfaces = {
      # Don't request DHCP on the physical interfaces
      enp1s0.useDHCP = false;
      enp2s0.useDHCP = false;
      
      # Handle the VLANs
      wan.useDHCP = false;
      lan = {
        ipv4.addresses = [{
          address = "10.1.1.1";
          prefixLength = 28;
        }];
      };
    };
  }; 

  time.timeZone = "America/New_York";
  networking.timeServers = options.networking.timeServers.default ++ [ "time.google.com" ]; 


# User stuff
  users.users = {
    router = {
      isNormalUser = true;
      home = "/home/router";
      description  = "manager user for ssh access";
      uid = 1111; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" ]; 
      hashedPasswordFile = "/stateful/sys-data/router-passwordHash"; #  mkpasswd -m sha-512 
    };
  };
  system.stateVersion = "24.11";
  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "hpsa" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];  
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
