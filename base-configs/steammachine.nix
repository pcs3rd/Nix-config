{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  services.openssh.enable = true;

  ####################
  # Boot & Kernel    #
  ####################
  boot = {
    initrd.systemd.enable = true;
    initrd.verbose = false;

    loader.systemd-boot.enable = true;
    loader.systemd-boot.configurationLimit = 2;
    loader.efi.canTouchEfiVariables = true;
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key.
    # It will just not appear on screen unless a key is pressed.
    loader.timeout = 0;

    # Silent boot, SteamOS-style.
    consoleLogLevel = 3;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
      "bgrt_disable=0"
    ];
    plymouth = {
      enable = true;
      theme = "nixos-bgrt";
      themePackages = with pkgs; [
        nixos-bgrt-plymouth
      ];
    };
  };

  ############
  # Security #
  ############
  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.sudo.wheelNeedsPassword = true;

  ###########
  # Audio   #
  ###########
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment the following
    jack.enable = true;
  };

  ###########
  # Network #
  ###########
  networking.networkmanager.enable = true;

  ##############
  # Boot speed #
  ##############
  # NetworkManager-wait-online blocks reaching the target until a network
  # connection is up, and systemd-udev-settle waits for all udev events to
  # finish before continuing — both are common multi-second boot stalls that
  # this box doesn't need (nothing here requires network before the gaming UI
  # starts, and there's no LVM/mdraid device needing udev to fully settle).
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.services.systemd-udev-settle.enable = false;

  #############
  # CPU       #
  #############
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  environment.systemPackages = with pkgs; [
    git
    tmux
  ];

  ###############
  # Users       #
  ###############
  users.users.steamos = {
    isNormalUser = true;
    home = "/home/steamos";
    description = "SteamOS user";
    extraGroups = [ "wheel" "networkmanager" "video" "seat" "audio" ];
    # mkpasswd -m sha-512 (default SteamNix credentials: user steamos / pass steamos)
    hashedPassword = "$6$qGgHrWutHq5TT2er$cvgvICABb6p1mUsueBslBjAP3FLWZz3Ey92H1OyG2sTa6qo7U77/ft79/ZxSIfhD6p0vxQO.ZsdegcMzoobB51";
  };

  # The games subvolume (disko-configs/steammachine.nix) is mounted at Steam's
  # default library path, /home/steamos/.local/share/Steam/steamapps, so games
  # install there with no manual "Add Library Folder" step. Because it's
  # several directories deep, systemd auto-creates each missing ancestor as
  # root:root when it sets up the mount — which would block Steam (running as
  # the steamos user) from ever populating ~/.local/share/Steam itself. Fix
  # ownership on that whole chain (non-recursive; files Steam creates below
  # these will already be owned by steamos since it's the process writing them).
  systemd.tmpfiles.rules = [
    "z /home/steamos/.local 0755 steamos users - -"
    "z /home/steamos/.local/share 0755 steamos users - -"
    "z /home/steamos/.local/share/Steam 0755 steamos users - -"
    "z /home/steamos/.local/share/Steam/steamapps 0755 steamos users - -"
  ];

  system.stateVersion = "25.05";
}
