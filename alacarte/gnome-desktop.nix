{ inputs, outputs, lib, pkgs, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.git
        pkgs.gh
        pkgs.gnomeExtensions.tailscale-status
        pkgs.gnomeExtensions.dash-to-dock
        pkgs.gnomeExtensions.clipboard-indicator
        pkgs.gnomeExtensions.tray-icons-reloaded
        pkgs.gnome-tweaks
        pkgs.firefox
        pkgs.google-chrome
        
    ];
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  networking.networkmanager.enable = true;
}
