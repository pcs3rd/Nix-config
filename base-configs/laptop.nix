{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports = [ 
    inputs.companion.nixosModules.default
    (modulesPath + "/installer/scan/not-detected.nix")
    ];
#https://github.com/noblepayne/bitfocus-companion-flake
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  boot.initrd.systemd.enable = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;
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

  environment.systemPackages = with pkgs; [
    google-chrome
    tmux
    vscode
    steam
    moonlight
    discord
    carla
    sbctl
    remmina
    mokutil
  ];
  programs.companion.enable = true;
  programs.companion.runAsService = true;
  programs.companion.user = "rdean3";
  programs.companion.group = "100";

  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = true;


  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
  };
# Network
  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";

# User stuff
  users.users = {
    rdean3 = {
      isNormalUser = true;
      description  = "Raymond Dean III";
      uid = 1000; 
      extraGroups = [ "wheel" "docker" "networkmanager" "storage" "dialout" ]; 
      hashedPassword = "$6$jjHT9q.f4rNdXvm6$tul/4JwWPSxSu7jr/dB3WF1RXjOcGeymbIZv5EsefHSPta2yL/.04F9FBFO6xEvXhxhylConjPmzbIrgxtXz.0"; #  mkpasswd -m sha-512 
    };
  };
  system.stateVersion = "25.11";
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
