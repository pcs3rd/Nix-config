{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports =
    [ (modulesPath + "/hardware/network/broadcom-43xx.nix")
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.openssh = {
    enable = true;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
    ];
  };
  environment.sessionVariables = { LIBVA_DRIVER_NAME = "i965"; }; # Optionally, set the environment variable
# Network
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  nixpkgs.config.allowUnfree = true;
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

    hardware.i2c.enable = true;
    environment.systemPackages = with pkgs; [ ddcutil ];

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
  
  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse # optional, to mount using 'ifuse'
];
}
