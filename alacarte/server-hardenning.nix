{ pkgs, lib, ... }:

{
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
        pkgs.browsh
        pkgs.firefox
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
    environment.systemPackages = with pkgs; [ clamav ];

}