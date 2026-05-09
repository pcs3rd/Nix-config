{ inputs, outputs, lib, pkgs, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.git
        pkgs.gh
        pkgs.gnomeExtensions.tailscale-status
        pkgs.gnomeExtensions.dash-to-dock
        pkgs.gnomeExtensions.clipboard-indicator
        pkgs.gnomeExtensions.tray-icons-reloaded
        pkgs.gnome-tweaks
        pkgs.gnome-remote-desktop
        pkgs.xrdp
    ];
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  networking.networkmanager.enable = true;
  services.gnome.gnome-remote-desktop.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];
  networking.firewall.allowedUDPPorts = [ 3389 ];

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  systemd.services.gnome-remote-desktop = {
  wantedBy = [ "graphical.target" ];
};
}
