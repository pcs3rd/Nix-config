{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
# Power options 
  powerManagement.cpuFreqGovernor = "powersave";

  ##############################
  #---------Monitoring---------#
  ##############################
  services.grafana = {
    enable = true;
    port = 8888;
    addr = "0.0.0.0";
    dataDir = "/stateful/grafana";
  };

  services.prometheus = {
    enable = true;
    port = 9990;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9991;
      };
    };
    scrapeConfigs = [
      {
        job_name = "chrysalis";
        static_configs = [{
          targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
    ];
  };
  ##############################
  #----------Network-----------#
  ##############################
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
    #"net.ipv6.conf.${name}.accept_ra" = 2;
    #"net.ipv6.conf.${name}.autoconf" = 1;
  };

  ##############################
  #----------PXE SERVER--------#
  ##############################

  services.pixiecore = {
    enable = true;
    openFirewall = true;
    dhcpNoBind = true;
    kernel = "https://factory.talos.dev/pxe/b8e8fbbe1b520989e6c52c8dc8303070cb42095997e76e812fa8892393e1d176/v1.9.2/metal-amd64";
  };


  # DHCP Server---------------------
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ "eth1" ];
      
      lease-database = {
        name = "/var/lib/kea/dhcp4-leases.csv";
        type = "memfile";
        persist = true;
        lfc-interval = 3600;
      };

      valid-lifetime = 4000;
      renew-timer = 1000;
      rebind-timer = 2000;

      subnet5 = [{
        id = 5;
        subnet = "10.56.84.0/24";
        pools = [{
          pool = "10.56.84.10 - 10.56.84.40";
        }];

        option-data = [{
          name = "routers";
          data = "10.56.84.1";
        }{
          name = "domain-name-servers";
          data = "1.1.1.1"; # Cloudflare DNS
        }];
      }];
    };
  };

  #Net config-----------
  networking = {
    interfaces = {
      "enp2s0f1" = {
        # DHCP needed to acquire IP for WAN
        useDHCP = true;
      };
      "enp2s0f0" = {
        # Static IP needed for LAN gateway
        useDHCP = false;
        ipv4.addresses = [{
          address = "10.56.84.1";
          prefixLength = 27;
        }];
      };
    };
    firewall.enable = lib.mkForce false;

    nftables = {
      enable = true;
      tables = {
        # Allow select IPv4 traffic
        filterV4 = {
          family = "ip";
          content = ''
            chain input {
              type filter hook input priority 0; policy drop;
              iifname "lo" accept comment "allow loopback traffic"
              iifname "eth1" accept comment "allow traffic from LAN"
              iifname "eth0" ct state established, related accept comment "allow established traffic from WAN"
              iifname "eth0" ip protocol icmp counter accept comment "allow ICMP traffic from WAN" 
              iifname "eth0" tcp dport 22 counter accept comment "allow SSH traffic from WAN"
              iifname "eth0" counter drop comment "drop all other traffic from WAN"
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
              iifname "eth1" oifname "eth0" accept comment "allow LAN connections to forward to WAN"
              iifname "eth0" oifname "eth1" ct state established, related accept comment "allow established WAN connections to forward to LAN"
            }
          '';
        };
        # Allow forwarded traffic out through WAN, masquerades IP
        natV4 = {
          family = "ip";
          content = ''
            chain postrouting {
              type nat hook postrouting priority 100; policy accept;
              oifname "eth0" masquerade comment "replace source address with WAN IP address"
            }
          '';
        };
        # Drops all IPv6 traffic
        filterV6 = {
          family = "ip6";
          content = ''
            chain input {
              type filter hook input priority 0; policy drop;
            }
            chain forward {
              type filter hook forward priority 0; policy drop;
            }
          '';
        };
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
