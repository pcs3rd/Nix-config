{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

  {

    config = {
      #nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
      nixpkgs.system = "aarch64-linux";
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
        adwaita-icon-theme  # Icon Theme
        tmux                # Virtual Terminal
        phosh-mobile-settings # Settings
        gnome-shell          # Shell functionality
      ];
      networking.nftables.enable = true;
      hardware.sensor.iio.enable = true;
      services.printing.enable = true;
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
      assertions = [
        { assertion = options.services.xserver.desktopManager.phosh.user.isDefined;
        message = ''
          `services.xserver.desktopManager.phosh.user` not set.
            When importing the phosh configuration in your system, you need to set `services.xserver.desktopManager.phosh.user` to the username of the session user.
        '';
        }
      ];  
      hardware.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
      };

      networking.networkmanager.enable = true;
      time.timeZone = "America/New_York";


      nix = {
        extraOptions = ''
          experimental-features = nix-command flakes
        '';
      };
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
