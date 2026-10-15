{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  system.stateVersion = "24.05";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  time.timeZone = "America/New_York";

  # ── Boot ────────────────────────────────────────────────────────────
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci" "ahci" "ohci_pci" "ehci_pci" "firewire_ohci"
        "usbhid" "uas" "sd_mod" "sdhci_pci" "hid_magicmouse"
      ];
      kernelModules = [ ];
      verbose = false;
    };

    kernelModules = [ "kvm-intel" "i2c-dev" "ddcci_backlight" ];
    # ddcci_backlight is out-of-tree; without this it never loads
    extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];

    extraModprobeConfig = ''
      options hid_magicmouse scroll_acceleration=1 scroll_speed=55 emulate_scroll_wheel=1 emulate_3button=0
    '';

    kernelParams = [
      # keep usbhid off the Bluetooth module's HID-proxy interfaces
      "usbhid.quirks=0x05ac:0x8294:0x0004"
      # silent boot
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "bgrt_disable=0"
    ];
    consoleLogLevel = 3;

    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = [ pkgs.nixos-bgrt-plymouth ];
    };

    # menu stays hidden unless a key is pressed
    loader.timeout = 0;
  };

  # ── Hardware ────────────────────────────────────────────────────────
  hardware = {
    enableAllFirmware = true;
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    i2c.enable = true;

    graphics = {
      enable = true;
      extraPackages = [ pkgs.intel-vaapi-driver ];
    };

    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "i965";

  # ── Input ───────────────────────────────────────────────────────────
  services.libinput.enable = true;
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

  # ── Audio ───────────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # bigger jitter buffer for phone → iMac Bluetooth audio
    wireplumber.extraConfig."51-bt-latency" = {
      "monitor.bluez.rules" = [{
        matches = [{ "node.name" = "~bluez_input.*"; }];
        actions.update-props."node.latency" = "2048/48000";
      }];
    };
  };

  # ── AirPlay receiver ────────────────────────────────────────────────
  services.avahi = {
    enable = true;
    publish = { enable = true; userServices = true; };
  };

  # AirPlay 2 timing daemon (needs root for ports 319/320)
  systemd.services.nqptp = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig.ExecStart = "${pkgs.nqptp}/bin/nqptp";
  };

  # runs in the user session so it can reach PipeWire
  systemd.user.services.shairport-sync = {
    wantedBy = [ "default.target" ];
    after = [ "pipewire.service" ];
    serviceConfig.ExecStart =
      "${pkgs.shairport-sync-airplay2}/bin/shairport-sync -a iMac -o pa";
  };

  # ── Networking ──────────────────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.firewall = {
    allowedTCPPorts = [ 3689 5000 7000 ];
    allowedUDPPorts = [ 319 320 5353 ];
    allowedUDPPortRanges = [
      { from = 6000;  to = 6009;  }
      { from = 32768; to = 60999; }
    ];
  };

  services.openssh.enable = true;

  # ── iPhone (USB) ────────────────────────────────────────────────────
  services.usbmuxd.enable = true;

  # ── Packages ────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    shairport-sync-airplay2
    nqptp
    ddcutil
    libimobiledevice
    ifuse
  ];
}
