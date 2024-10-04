{ config, lib, pkgs, ... }:
{
  specialisation = {
    Recovery_Mode.configuration = {
      system.nixos.tags = [ "Recovery_Mode" ];
      services.nixosManual.enable = lib.mkForce true;
      security.sudo.enable = false;
      services.mingetty.autologinUser = "recovery";
      boot.initrd.kernelModules = [ "ext4" "btrfs" ];
      environment.defaultPackages = lib.mkForce [
        pkgs.tint2
        pkgs.tmux
        pkgs.alacritty
        pkgs.gparted
      ];
      services.xserver.displayManager.gdm.enable = lib.mkForce false;
      services.xserver.desktopManager.gnome.enable = lib.mkForce false;
      services.xserver.windowManager.openbox.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = "recovery";
      services.displayManager.defaultSession = "none+openbox";



      users.users.recovery = {
          isNormalUser = true;
          uid = 1462; # This should not allow writing to files.
          extraGroups = [ "networkmanager" "video" ];
        };
      };
  };
}

