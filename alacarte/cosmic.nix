{ inputs, outputs, lib, pkgs, ... }:{
  # Enable the COSMIC login manager
  services.displayManager.cosmic-greeter.enable = true;

  # Enable the COSMIC desktop environment
  services.desktopManager.cosmic.enable = true;

  services.system76-scheduler.enable = true;
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
  networking.networkmanager.enable = true;
  environment.systemPackages = with pkgs; [
   cosmic-ext-tweaks
  ];
}