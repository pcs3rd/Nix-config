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
    user = "operator";
  };
  mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;
  users.users.operator = {
    isNormalUser = true;
    home  = "/home/operator";
    description  = "mobile-nixos";
    extraGroups  = [ "wheel" "networkmanager" "dialout" "feedbackd" "networkmanager" "video" ];
    hashedPassword = "$y$j9T$XC.lwIBT14ILS8kl.y6TS0$iJ/xXhTwGpAh2.aVe5E4NkEG3nCLClwH4AECFZeNUi/"; # 1234 by default
  };
 # environment.plasma5.mobile.excludePackages = [
 #   pkgs.kdePackages.kasts
 #   pkgs.kdePackages.plasma-dialer
 #   
 # ];
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
  #hardware.pulseaudio.enable = lib.mkDefault false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = false;
  powerManagement.enable = true;
  services.libinput.enable = true;
  services.displayManager.defaultSession = "plasma-mobile";
  services.displayManager.autoLogin.enable = true;
  services.printing.enable = true;
  networking.firewall.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  
  environment.systemPackages = [
    pkgs.firefox
    pkgs.styluslabs-write
    pkgs.libevdev
    pkgs.pkg-config
  ];
  system.stateVersion = "25.05";

}

