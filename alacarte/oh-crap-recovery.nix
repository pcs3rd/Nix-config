{ config, lib, pkgs, ... }:
{
  specialisation = {
    Recovery_Mode.configuration = {
      system.nixos.tags = [ "Recovery_Mode" ];
      services.xserver.desktopManager.gnome.enable = lib.mkForce false;
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
      services.xserver.windowManager.openbox.enable = true;
      services.xserver.displayManager.lightdm.enable = true;
      services.displayManager.autoLogin.enable = true;
      services.displayManager.autoLogin.user = "recovery";
      services.displayManager.defaultSession = "none+openbox";




      users.users.recovery = {
          isNormalUser = true;
          uid = 1002;
          extraGroups = [ "networkmanager" "video" ];
        };
      };
      fileSystems."/" = lib.mkForce {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=20M" "mode=755" ];
  };
  fileSystems."/home" = lib.mkForce {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=20M" "mode=755" ];
  };
};
}

