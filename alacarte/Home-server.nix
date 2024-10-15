{ inputs, outputs, lib, pkgs, ... }:{
  services = {
    unifi.enable = true; 
    adguardhome = {
      enable = true; 
      settings = {
        http = {
          address = "172.0.0.1:3003"
        }; 
        dns = {
          upstream_dns = [
            8.8.8.8
            1.1.1.1
          ];
        };
        filtering = {
          protection_enabled = true; 
          filtering_enabled = true; 
          parental_enabled = false; 
          safe_search = {
            enabled = true; 
          };
        }; 
        filters = map(url: { enabled = true; url = url; }) [
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_9.txt"  # The Big List of Hacked Malware Web Sites
          "https://adguardteam.github.io/HostlistsRegistry/assets/filter_11.txt"  # malicious url blocklist
        ];
      };
    };
  };
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    virtualHosts."unifi.local" = {
      forceSSL = true;
      useACMEHost = "unifi.local";
      locations."/" = {
        proxyPass = "https://127.0.0.1:8443";
        proxyWebsockets = true;
      };
    };
  };
}