{ inputs, outputs, lib, pkgs, ... }:{
    services.desktopManager.lomiri.enable = true;
    services.displayManager.defaultSession = "lomiri";
}