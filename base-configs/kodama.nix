{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

  {

    config = {
      nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
      mobile.beautification = {
        silentBoot = lib.mkDefault true;
        splash = lib.mkDefault true;
      };
  
      services.xserver.desktopManager.phosh = {
        enable = true;
        group = "users";
      };
  
      programs.calls.enable = true;
  
      environment.systemPackages = with pkgs; [
        # Disabled since it uses `olm` which was marked insecure.
        #chatty              # IM and SMS
        epiphany            # Web browser
        gnome-console       # Terminal
        megapixels          # Camera
      ];
  
      hardware.sensor.iio.enable = true;
  
      assertions = [
        { assertion = options.services.xserver.desktopManager.phosh.user.isDefined;
        message = ''
          `services.xserver.desktopManager.phosh.user` not set.
            When importing the phosh configuration in your system, you need to set `services.xserver.desktopManager.phosh.user` to the username of the session user.
        '';
        }
      ];
    
      services.xserver.desktopManager.phosh = {
        user = "mobile-nixos";
      };
      mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;
      users.users.mobile-nixos = {
        isNormalUser = true;
        home  = "/home/mobile-nixos";
        description  = "mobile-nixos";
        extraGroups  = [ "wheel" "networkmanager" "dialout" "feedbackd" "networkmanager" "video" ];
        hashedPassword = "$y$j9T$mPFMquJN3r6ENhAT0pQ1n.$7stMBcOs7CwkNxF5EvwlJW9H54jdBPm/GE8PvODiKk6"; #  mkpasswd
      };
    };
  }
