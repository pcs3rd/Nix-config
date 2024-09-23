{ ... }:

{
    networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 80 443 ];
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
    environment.defaultPackages = lib.mkForce [];
    services.openssh = {
        passwordAuthentication = false;
        allowSFTP = false; # Don't set this if you need sftp
        challengeResponseAuthentication = false;
        extraConfig = ''
        AllowTcpForwarding yes
        X11Forwarding no
        AllowAgentForwarding no
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
        '';
    };
    environment.systemPackages = with pkgs; [ clamav ];

}