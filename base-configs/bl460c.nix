{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
# Power options 
  powerManagement.cpuFreqGovernor = "powersave"

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
    "net.ipv6.conf.${name}.accept_ra" = 2;
    "net.ipv6.conf.${name}.autoconf" = 1;
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

  ##############################
  #----------ROUTING-----------#
  ##############################

  #----------DHCP SERVER-------#
  services.dhcpd4 = {
      enable = true;
      interfaces = [ "enp2s0" ];
      extraConfig = ''
        option domain-name-servers 8.8.8.8, 1.1.1.1;
        option subnet-mask 255.255.255.224;

        subnet 10.56.84.0 netmask 255.255.255.224 {
          option broadcast-address 10.56.84.255;
          option routers 10.56.84.1;
          option domain-name-servers 8.8.8.8;
          interface enp2s0;
          range 10.56.84.2 10.56.84.34;
        }
      '';
    };
  #---------BIND CFG-----------#
  services.bind = {
    enable = false;
    zones = {
      "example.com" = {
        master = true;
        file = pkgs.writeText "zone-example.com" ''
          $ORIGIN example.com.
          $TTL    1h
          @            IN      SOA     ns1 hostmaster (
                                           1    ; Serial
                                           3h   ; Refresh
                                           1h   ; Retry
                                           1w   ; Expire
                                           1h)  ; Negative Cache TTL
                       IN      NS      ns1
                       IN      NS      ns2

          @            IN      A       203.0.113.1
                       IN      AAAA    2001:db8:113::1
                       IN      MX      10 mail
                       IN      TXT     "v=spf1 mx"

          www          IN      A       203.0.113.1
                       IN      AAAA    2001:db8:113::1

          ns1          IN      A       203.0.113.4
                       IN      AAAA    2001:db8:113::4

          ns2          IN      A       198.51.100.5
                       IN      AAAA    2001:db8:5100::5
        '';
      };
    };
  };


  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
  };

  #---------Ifaces CFG-----------#
  networking = {

    hostName = "BackplaneManager";
    nameservers = [ "" ]; #TODO: IP of host on VLAN
    firewall.enable = false;

    interfaces = {
      enp1s0 = { # UPSTREAM ROUTE
        useDHCP = true;
      };
      enp2s0 = { # DOWNSTREAM/BACKPLANE
        useDHCP = false;
        ipv4.addresses = [{
          address = "10.56.84.1";
          prefixLength = 27;
        }];
      };
    };

    nftables = {
      enable = true;
      ruleset = ''
        table ip filter {
          chain input {
            type filter hook input priority 0; policy drop;

            iifname { "enp2s0" } accept comment "Allow local network to access the router"
            iifname "enp1s0" ct state { established, related } accept comment "Allow established traffic"
            iifname "enp1s0" icmp type { echo-request, destination-unreachable, time-exceeded } counter accept comment "Allow select ICMP"
            iifname "enp1s0" counter drop comment "Drop all other unsolicited traffic from wan"
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            iifname { "enp2s0" } oifname { "enp1s0" } accept comment "Allow trusted LAN to WAN"
            iifname { "enp1s0" } oifname { "enp2s0" } ct state established, related accept comment "Allow established back to LANs"
          }
        }

        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            oifname "enp1s0" masquerade
          } 
        }

        table ip6 filter {
	        chain input {
            type filter hook input priority 0; policy drop;
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
          }
        }
      '';
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
