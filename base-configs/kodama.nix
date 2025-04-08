{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

  {
  nixpkgs.system = "aarch64-linux";

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

  mobile.beautification = {
    silentBoot = lib.mkDefault true;
    splash = lib.mkDefault true;
  };

  services.xserver = {
    enable = true;

    desktopManager.plasma5.mobile.enable = true;

    displayManager.lightdm = {
      enable = true;
      # Workaround for autologin only working at first launch.
      # A logout or session crashing will show the login screen otherwise.
      extraSeatDefaults = ''
        session-cleanup-script=${pkgs.procps}/bin/pkill -P1 -fx ${pkgs.lightdm}/sbin/lightdm
      '';
    };

  };
  services.displayManager.autoLogin.user = "mobile-nixos";
  hardware.bluetooth.enable = true;
  services.pipewire.enable = lib.mkDefault true;
  hardware.pulseaudio.enable = lib.mkDefault false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  powerManagement.enable = true;
  services.libinput.enable = true;
  services.displayManager.defaultSession = "plasma-mobile";
  services.displayManager.autoLogin.enable = true;
  environment.systemPackages = [
    pkgs.firefox
  ];
}

