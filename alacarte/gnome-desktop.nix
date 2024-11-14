{
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.gnome.excludePackages = with pkgs; [
    epiphany # web browser
    gnome.geary # email reader. Up to 24.05. Starting from 24.11 the package name is just geary.
    evince # document viewer
  ];
}
