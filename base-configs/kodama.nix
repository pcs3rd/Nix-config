{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

  {
  nixpkgs.system = "aarch64-linux";

  time.timeZone = "America/New_York";
  nix = {
    extraOptions = ''
    experimental-features = nix-command flakes
    '';
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

xserver.desktopManager.phosh = {
  enable = true;
  user = "operator";
  group = "users";
  # for better compatibility with x11 applications
  phocConfig.xwayland = "immediate";
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
    pkgs.wsjtx
    pkgs.fldigi
    pkgs.hamrs
    pkgs.hamlib
    pkgs.hamtransfer
    pkgs.ax25-apps
    pkgs.digiham
    pkgs.tlf
    pkgs.grig
    pkgs.klog
    pkgs.libax25
    pkgs.flex-ncat
    pkgs.gpredict
    
  ];
  system.stateVersion = "25.05";

}

