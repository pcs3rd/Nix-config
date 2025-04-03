defaultUserName:
{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

{
  imports = [
    ../home-configs/raymond.nix
  ];

  config = {
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
      user = "${defaultUserName}";
    };
    mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;

  };
}
