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
    boot.kernelModules = [ "cec" ];
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
  environment.systemPackages = [
    (pkgs.symlinkJoin {
      name = "cec-utils-wrapped";
      paths = [ pkgs.cec-utils ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/cecc-client --prefix LD_LIBRARY_PATH : "${pkgs.libcec}/lib"
        wrapProgram $out/bin/cec-client --prefix LD_LIBRARY_PATH : "${pkgs.libcec}/lib"
      '';
    })
  ];
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
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
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
    libcec
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
  users.groups.cec = {};
  services.udev.extraRules = ''
    KERNEL=="cec[0-9]*", GROUP="video", MODE="0660"
  '';
  users.users.steamos.extraGroups = [ "video" ];
  # The games subvolume (disko-configs/steammachine.nix) is mounted at Steam's
  # default library path, /home/steamos/.local/share/Steam/steamapps, so games
  # install there with no manual "Add Library Folder" step. Because it's
  # several directories deep, systemd auto-creates each missing ancestor as
  # root:root when it sets up that mount.
  #
  # This used to be a systemd.tmpfiles.rules fixup, but tmpfiles only runs
  # once early at boot with no guaranteed ordering against the steamapps
  # mount unit — if the mount happened to land after tmpfiles ran, the
  # ancestor chain stayed root:root and Steam's bootstrap extraction failed
  # outright ("tar: ./ubuntu12_64: Cannot mkdir: Permission denied"). A
  # oneshot service with RequiresMountsFor is the correct tool here: systemd
  # resolves the path to the right mount unit itself and guarantees this
  # runs strictly after it's mounted, every boot.
  systemd.services.fix-steam-client-ownership = {
    description = "Fix ownership of ~/.local/share/Steam ancestor dirs after the steamapps mount";
    wantedBy = [ "multi-user.target" ];
    unitConfig.RequiresMountsFor = [ "/home/steamos/.local/share/Steam/steamapps" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/chown steamos:users /home/steamos/.local /home/steamos/.local/share /home/steamos/.local/share/Steam /home/steamos/.local/share/Steam/steamapps";
    };
  };

  system.stateVersion = "25.05";
}
