# SteamOS-like experience via Jovian-NixOS instead of the SteamNix wrapper repo.
# Must be used on a host built with unstable-nixpkgs.lib.nixosSystem (see flake.nix,
# host "steammachine") — Jovian's overlay (decky-loader, patched steam/gamescope
# packages) is developed against nixos-unstable and isn't guaranteed to evaluate
# cleanly on our stable nixpkgs channel.
{ inputs, outputs, lib, pkgs, ... }:
{
  imports = [ inputs.jovian.nixosModules.default ];

  nixpkgs.overlays = [
    inputs.jovian.overlays.default
    (final: prev: {
      # Packaging bug in the pinned nixpkgs revision: mangohud's `patches`
      # list includes 0805396e579c5f1ea27e2e2a78030d8ef6ce1994.diff twice, so
      # `patch` fails applying it the second time ("Reversed (or previously
      # applied) patch detected!"), which is fatal in the non-interactive Nix
      # sandbox. gamescope-session depends on mangohud, so this took the
      # whole Steam session build down with it. Dedupe until upstream fixes
      # it (worth checking `nix flake lock --update-input unstable-nixpkgs`
      # occasionally to see if this override can be dropped).
      mangohud = prev.mangohud.overrideAttrs (old: {
        patches = lib.unique old.patches;
      });
    })
  ];

  # No traditional desktop stack — gamescope is the "window manager".
  services.xserver.enable = false;

  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "steamos"; # must match users.users.steamos in base-configs/steammachine.nix
      # "Switch to Desktop" from Gaming Mode drops into COSMIC instead of relaunching Gaming Mode.
      desktopSession = "cosmic";
    };
    hardware.has.amd.gpu = true; # set to false if this box isn't AMD
    # Disabled: upstream decky-loader uses pnpm to build its frontend. Nix
    # builds that hermetically (no live registry access, pre-hashed deps), so
    # the pnpm supply-chain CVEs don't really apply here — but if you want zero
    # pnpm anywhere in the closure, this is the one thing that pulls it in.
    decky-loader.enable = false;
    steamos.useSteamOSConfig = true;
  };

  # jovian.hardware.has.amd.gpu already handles AMD early KMS itself (adds
  # "amdgpu" to boot.initrd.kernelModules). nixpkgs' own hardware.amdgpu.initrd
  # mechanism does the same thing a different way — leaving both on risks the
  # two fighting over initrd module ordering. SteamNix disables this for the
  # same reason.
  hardware.amdgpu.initrd.enable = false;

  # Fast suspend/resume, SteamOS-style: s2idle keeps enough powered to resume
  # almost instantly (press power button, you're back), at the cost of higher
  # power draw than a full S3 suspend. powerbuttond/vpower (installed by
  # jovian.steam.enable) are what actually drive the power-button-to-suspend
  # behavior; this just makes sure the kernel picks the fast wake path instead
  # of falling back to whatever the board's ACPI tables default to.
  # Swap to "deep" instead if you'd rather prioritize standby power draw over
  # wake speed.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  # COSMIC only needs to exist as a session for jovian.steam.desktopSession to
  # switch to — jovian owns the display manager (sddm + autologin) itself when
  # jovian.steam.autoStart is enabled, so no cosmic-greeter here.
  services.desktopManager.cosmic.enable = true;
  services.system76-scheduler.enable = true;

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General = {
    MultiProfile = "multiple";
    FastConnectable = true;
  };

  environment.sessionVariables = {
    COSMIC_DATA_CONTROL_ENABLED = "1";
    PROTON_USE_NTSYNC = "1";
    ENABLE_HDR_WSI = "1";
    DXVK_HDR = "1";
    PROTON_ENABLE_AMD_AGS = "1";
    PROTON_ENABLE_NVAPI = "1";
    ENABLE_GAMESCOPE_WSI = "1";
    STEAM_MULTIPLE_XWAYLANDS = "1";
  };

  # programs.steam.enable is turned on automatically by jovian.steam.enable;
  # this adds Proton-GE, desktop-mode extras, and opens the firewall for
  # Remote Play streaming and Local Network Game Transfers (both blocked by
  # the default firewall otherwise).
  programs.steam.extraCompatPackages = with pkgs; [ proton-ge-bin ];
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.localNetworkGameTransfers.openFirewall = true;

  environment.systemPackages = with pkgs; [
    steam-run
    protonup-qt
    firefox
  ];

  # Sunshine: game-stream server for Moonlight clients — a Remote Play
  # alternative/complement that also works for non-Steam content.
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };

  # mDNS advertisement so Moonlight clients can find this box on the LAN
  # without typing an IP.
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };
}
