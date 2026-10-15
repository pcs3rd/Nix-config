{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports =
    [ (modulesPath + "/hardware/network/broadcom-43xx.nix")
      (modulesPath + "/installer/scan/not-detected.nix")
    ];
  services.avahi = {
    enable = true;
    publish = { enable = true; userServices = true; };
  };
  
  environment.systemPackages = [ pkgs.shairport-sync-airplay2 pkgs.nqptp ];
  
  # AirPlay 2 timing daemon (needs root for ports 319/320)
  systemd.services.nqptp = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig.ExecStart = "${pkgs.nqptp}/bin/nqptp";
  };
  
  # receiver runs in your session so it reaches PipeWire
  systemd.user.services.shairport-sync = {
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" ];
    serviceConfig.ExecStart =
      "${pkgs.shairport-sync-airplay2}/bin/shairport-sync -a iMac -o pa";
  };
  
  networking.firewall = {
    allowedTCPPorts = [ 3689 5000 7000 ];
    allowedUDPPorts = [ 319 320 5353 ];
    allowedUDPPortRanges = [ { from = 6000; to = 6009; } { from = 32768; to = 60999; } ];
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.openssh = {
    enable = true;
  };
  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
    ];
  };
  environment.sessionVariables = { LIBVA_DRIVER_NAME = "i965"; }; # Optionally, set the environment variable
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
# Network
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pipewire.wireplumber.extraConfig."51-bt-latency" = {
    "monitor.bluez.rules" = [{
      matches = [{ "node.name" = "~bluez_input.*"; }];
      actions.update-props."node.latency" = "2048/48000";
    }];
  };
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

    hardware.i2c.enable = true;
    environment.systemPackages = with pkgs; [ 
      ddcutil
      libimobiledevice
      ifuse # optional, to mount using 'ifuse' 
    ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
    hardware = {
    # Ensure libinput is enabled for input handling
    opengl.enable = true;
    };
    boot.extraModprobeConfig = ''
    options hid_magicmouse scroll_acceleration=1 scroll_speed=55 emulate_scroll_wheel=1 emulate_3button=0
    '';
    services.xserver.inputClassSections = [
    ''
        Identifier "Apple Magic Mouse"
        MatchIsPointer "on"
        MatchProduct "Magic Mouse"
        Driver "libinput"
        Option "ScrollMethod" "twofinger"
        Option "NaturalScrolling" "true"
    ''
    ];
services.xserver.libinput.enable = true;
  system.stateVersion = "24.05";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "ohci_pci" "ehci_pci" "firewire_ohci" "usbhid" "uas" "sd_mod" "sdhci_pci" "hid-magicmouse"];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" "i2c-dev" "ddcci_backlight" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot = {
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = with pkgs; [
        nixos-bgrt-plymouth
      ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "usbhid.quirks=0x05ac:0x8294:0x0004"
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "bgrt_disable=0" 
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };
  services.usbmuxd.enable = true;
}
