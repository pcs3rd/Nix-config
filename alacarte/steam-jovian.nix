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

      # Upstream's gamescope-session script (Valve's own, from
      # PKGBUILDs-mirror) hardcodes the Steam Deck's panel resolution
      # (1280x800) straight into its `exec gamescope ... -w 1280 -h 800 ...`
      # invocation — no env var or NixOS option controls it. On this box
      # that means gamescope renders internally at 1280x800 and upscales to
      # fill the TV's real 1920x1080 output. Patch the shipped script to
      # render natively instead.
      #
      # Live alternative that needs no rebuild: Steam's own Settings >
      # Display > Resolution does the same thing and persists it to
      # ~/.config/gamescope/modes.cfg — this override just makes that the
      # default from first boot instead of something you set by hand once.
      gamescope-session = prev.gamescope-session.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace gamescope-session \
            --replace-fail "-w 1280 -h 800" "-w 1920 -h 1080"
          substituteInPlace gamescope-session \
            --replace-fail "-O '*',eDP-1" "-O '*',eDP-1 --expose-wayland"
        '';
      });

      # Known, unfixed upstream regression: nixpkgs' current sunshine build
      # segfaults on connect when capSysAdmin is used (the mode required for
      # DRM/KMS capture on a non-wlroots Wayland compositor like gamescope) —
      # https://github.com/NixOS/nixpkgs/issues/475181. No fix yet as of this
      # writing; the reporter's own workaround, confirmed working, is the
      # last-good (25.05/stable) sunshine build. Pull it from our regular
      # `nixpkgs` input instead of unstable-nixpkgs.
      sunshine = (import inputs.nixpkgs {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).sunshine;
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
    # Re-enabled. (It was off earlier over pnpm-as-a-build-tool concerns —
    # see the pnpm conversation elsewhere in this repo's history; Nix builds
    # it hermetically with no live registry access, so that risk is mostly
    # theoretical.) One or more of decky-loader's dependencies is currently
    # flagged insecure in nixpkgs, so it won't evaluate without explicitly
    # allowing that below.
    decky-loader.enable = true;
    # decky-loader shells out to `systemctl` internally, but its systemd
    # service's PATH doesn't include it by default — logs
    # "FileNotFoundError: ... 'systemctl'" without this.
    decky-loader.extraPackages = [ pkgs.systemd ];
    steamos.useSteamOSConfig = true;
  };

  # Required for jovian.decky-loader.enable — nixpkgs currently flags one of
  # its dependencies as insecure (known CVE, unpatched upstream). This is a
  # blanket allow rather than pinning an exact "name-version" string because
  # that string changes on every version bump; narrow it with
  # nixpkgs.config.permittedInsecurePackages = [ "exact-name-version" ]
  # instead if you'd rather only allow the specific package once you know
  # which one it is (the eval error names it exactly).
  nixpkgs.config.allowInsecurePredicate = _: true;

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

  # Reverted: an earlier attempt to fix "Steam relaunches in Big Picture when
  # switching to Desktop Mode" by rescoping steam-launcher.service to
  # gamescope-session.target broke it outright ("Failed to load environment
  # files" — EnvironmentFile=%t/gamescope-environment didn't exist yet).
  # Turns out graphical-session.target isn't a generic "any desktop" target
  # here: gamescope-session.service is Type=notify and doesn't signal ready
  # until *after* it writes that environment file, and it's Before=/PartOf=
  # graphical-session.target — so that target genuinely can't activate
  # early. gamescope-session.target then starts Steam via Upholds=
  # steam-launcher.service, not a WantedBy= from steam-launcher's own side.
  # My override raced ahead of that chain instead of respecting it. The
  # original bug (if it's still reproducible) needs a correctly-understood
  # fix, not this one — left alone for now rather than shipping something
  # broken.

  zramSwap.enable = true;
  zramSwap.algorithm = "zstd";

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings.General = {
    MultiProfile = "multiple";
    FastConnectable = true;
  };

  # Best-effort "wake from suspend via controller" support. This is
  # genuinely hardware/firmware dependent, not guaranteed — several
  # documented cases of this simply not working on certain Bluetooth
  # chipsets even with the wakeup flag set correctly. Pairs with
  # mem_sleep_default=s2idle above: s2idle keeps more hardware (including
  # radios) powered during suspend than deep S3, which wake-on-Bluetooth/USB
  # generally needs to have any chance of working.
  systemd.services.enable-usb-wakeup = {
    description = "Enable USB wakeup on all root hubs (for waking from suspend via Bluetooth/USB controllers)";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      for hub in /sys/bus/usb/devices/usb*; do
        echo enabled > "$hub/power/wakeup" 2>/dev/null || true
      done
    '';
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
    discord
    # Discord's own in-app overlay doesn't work under Wayland/gamescope.
    # discover-overlay is a separate, purpose-built replacement that reads
    # voice-channel state over Discord's local websocket API instead of
    # hooking the game's renderer, and it draws via gtk-layer-shell — hence
    # the --expose-wayland patch on gamescope-session above, which it needs
    # to render as a proper compositor overlay layer.
    discover-overlay

    # The mirror image of jovian.steam.desktopSession above: that gets you
    # from Gaming Mode into COSMIC; this app (shown in COSMIC's launcher
    # while in Desktop Mode) gets you back to Gaming Mode. steamosctl is
    # steamos-manager's CLI, the same tool jovian itself uses internally for
    # session switching.
    (makeDesktopItem {
      name = "return-to-gaming-mode";
      desktopName = "Return to Gaming Mode";
      comment = "Switch back to Steam's Gaming Mode (gamescope)";
      icon = "steam";
      # Desktop Entry's Exec is a plain argv, not run through a shell — no
      # &&, so wrap the two steamosctl calls in an actual script instead.
      exec = "${writeShellScript "return-to-gaming-mode" ''
        set -e
        ${steamos-manager}/bin/steamosctl set-default-login-mode game
        ${steamos-manager}/bin/steamosctl switch-to-game-mode
      ''}";
      terminal = false;
      categories = [ "System" ];
    })
  ];

  # Discover Overlay runs continuously alongside whatever you're playing,
  # rather than being launched as a discrete app — start it with the
  # gamescope session and keep it alive.
  systemd.user.services.discover-overlay = {
    description = "Discover Overlay (Discord voice/notification overlay)";
    wantedBy = [ "gamescope-session.target" ];
    partOf = [ "gamescope-session.target" ];
    after = [ "gamescope-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.discover-overlay}/bin/discover-overlay";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Sunshine: game-stream server for Moonlight clients — a Remote Play
  # alternative/complement that also works for non-Steam content. Setting
  # `applications` exposes Firefox and Discord as launchable/streamable
  # "apps" to Moonlight clients (Sunshine's equivalent of Steam's non-Steam
  # game shortcuts) alongside the default full "Desktop" stream. Note this
  # takes over app configuration entirely — the web UI's app editor is
  # disabled once this is set.
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
    # Crash root cause, confirmed from the coredump: Sunshine's default
    # encoder probe tries Vulkan Video H264 first, which this GPU
    # (Polaris/RX 570) doesn't support — the encoder correctly logs
    # "Encoding of h264 is not supported by this device" and then segfaults
    # trying to initialize it anyway instead of falling back cleanly.
    # Vulkan Video encode is RDNA2+ only; force VA-API instead, which AMD has
    # supported on Linux for years and which this card handles fine.
    settings.encoder = "vaapi";
    applications = {
      apps = [
        { name = "Desktop"; }
        {
          name = "Firefox";
          cmd = "firefox";
          auto-detach = "true";
        }
        {
          name = "Discord";
          cmd = "discord";
          auto-detach = "true";
        }
      ];
    };
  };

  # nixpkgs' sunshine module wires its user unit to graphical-session.target
  # (wantedBy/partOf/wants/after), but Jovian's gamescope-session never
  # activates that target — it uses its own gamescope-session.target — so
  # autoStart alone doesn't actually bring Sunshine up under Steam's Gaming
  # Mode. Add the gamescope target alongside the default so Sunshine starts
  # with the gamescope Wayland session specifically (it'll still also start
  # under a traditional desktop session, e.g. jovian.steam.desktopSession's
  # COSMIC, since graphical-session.target is untouched).
  systemd.user.services.sunshine = {
    wantedBy = [ "gamescope-session.target" ];
    partOf = [ "gamescope-session.target" ];
    wants = [ "gamescope-session.target" ];
    after = [ "gamescope-session.target" ];
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
