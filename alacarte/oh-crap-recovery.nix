{ config, lib, pkgs, ... }:
let
  autostart = ''
    #!${pkgs.bash}/bin/bash
    # End all lines with '&' to not halt startup script execution
  '';

  inherit (pkgs) writeScript;
in 
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
    networking.networkmanager.enable = true;

  services.xserver = {
    enable = true;
    layout = "us"; # keyboard layout
    libinput.enable = true;

    # Let lightdm handle autologin
    displayManager.lightdm = {
      enable = true;
      autoLogin = {
        enable = lib.mkForce true;
        timeout = 0;
        user = "recovery";
      };
    };
    windowManager.openbox.enable = true;
    displayManager.defaultSession = "none+openbox";
  };

  nixpkgs.overlays = with pkgs; [
    (self: super: {
      openbox = super.openbox.overrideAttrs (oldAttrs: rec {
        postFixup = ''
          ln -sf /etc/openbox/autostart $out/etc/xdg/openbox/autostart
        '';
      });
    })
  ];
  environment.etc."openbox/autostart".source = writeScript "autostart" autostart;


  users.users.recovery = {
        isNormalUser = true;
        uid = 1002;
        extraGroups = [ "networkmanager" "video" ];
      };
    };
  };
  fileSystems."/" = lib.mkForce {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=1G" "mode=755" ];
  };

}
