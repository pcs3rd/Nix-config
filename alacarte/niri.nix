{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    waypaper
    waybar
    swaylock-effects
    swww
    swaynotificationcenter
    wl-clipboard-rs
    git
    curl
    wlogout
    tmux
    wofi
    ghostty
    adw-gtk3
    papirus-icon-theme
    nautilus
    ly
    btop
    xwayland
    xwayland-satellite
    wayland-utils # Wayland utilities
  ];
  xdg.portal.wlr.enable = true;
  fonts = {
    fontconfig.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
  services = {
    displayManager.enable = true;
    displayManager.ly.enable = true;
    # services.openssh.enable = true;
  };

  programs = {
    nix-ld.enable = true;
    niri.enable = true;
    xwayland.enable = true;
  };
  environment.variables = {
    OZONE_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
  };
}