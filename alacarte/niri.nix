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
    vscode
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
    xserver.enable = true;
    displayManager.enable = true;
    xserver.displayManager.lightdm.enable = true;
    # services.openssh.enable = true;
    displayManager.autoLogin.enable = true;
    displayManager.autoLogin.user = "operator";
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