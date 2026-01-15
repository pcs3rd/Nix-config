{ inputs, outputs, lib, pkgs, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.git
        pkgs.gh
        pkgs.gnomeExtensions.tailscale-status
        pkgs.gnomeExtensions.dock-from-dash
        pkgs.gnomeExtensions.frippery-applications-menu
        pkgs.gnomeExtensions.clipboard-indicator
        pkgs.gnome-tweaks
        
    ];
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  networking.networkmanager.enable = true;
}
