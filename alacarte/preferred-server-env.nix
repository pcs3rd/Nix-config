{ inputs, outputs, lib, pkgs, ... }:{
  i18n.defaultLocale = "en_US.UTF-8";
  environment.variables = {
    "EDITOR" = "nano";
  };
  hardware.raid.HPSmartArray.enable;
  services.davfs2.enable = true;
  documentation.enable = false; # documentation of packages
  documentation.nixos.enable = false; # nixos documentation
  documentation.man.enable = false; # manual pages and the man command
  documentation.info.enable = false; # info pages and the info command
  documentation.doc.enable = false; # documentation distributed in packages' /share/doc
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  services.devmon.enable = true; # I want to auto-mount disks.
  services.gvfs.enable = true; 
  services.udisks2.enable = true;

  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [ "time.cloudflare.com" ];
  };

    networking.firewall = {
        enable = false;
        allowedTCPPorts = [ 80 443 22 ];
        # allowedUDPPortRanges = [
        #    { from = 4000; to = 4007; }
        #    { from = 8000; to = 8010; }
        #];
    };
    networking.firewall.trustedInterfaces = [ "tailscale0" ]; # Trust tailscale0
    nix.allowedUsers = [ "@wheel" ];
    security.auditd.enable = true;
    security.audit.enable = true;
    security.audit.rules = [
        "-a exit,always -F arch=b64 -S execve"
    ];
    security.sudo.execWheelOnly = true;
    environment.defaultPackages = lib.mkForce [
        pkgs.bash
        pkgs.git
        pkgs.nix
        pkgs.nano
        pkgs.tmux
        pkgs.htop
        pkgs.mtm
        pkgs.smartmontools
        pkgs.lazydocker
        pkgs.systemctl-tui
    ];
    services.openssh = {
        enable = true;
        passwordAuthentication = true;
        allowSFTP = true; # Don't set this if you need sftp
        challengeResponseAuthentication = false;
        extraConfig = ''
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        #AuthenticationMethods publickey
        '';
    };

users.motd = "Stickpile Environment Installer for PROD/DEV hosts.";
}
