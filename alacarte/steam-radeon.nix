{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
    boot.kernelPatches = [
        {
            name = "amdgpu-ignore-ctx-privileges";
            patch = pkgs.fetchpatch {
            name = "cap_sys_nice_begone.patch";
            url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
            hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
            };
        }
    ];
    services.wivrn = {
        enable = true;
        openFirewall = true;

        # Write information to /etc/xdg/openxr/1/active_runtime.json, VR applications
        # will automatically read this and work with WiVRn (Note: This does not currently
        # apply for games run in Valve's Proton)
            defaultRuntime = true;

        # Run WiVRn as a systemd service on startup
        autoStart = true;

        # If you're running this with an nVidia GPU and want to use GPU Encoding (and don't otherwise have CUDA enabled system wide), you need to override the cudaSupport variable.
        package = (pkgs.wivrn.override { cudaSupport = true; });

        # You should use the default configuration (which is no configuration), as that works the best out of the box.
        # However, if you need to configure something see https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md for configuration options and https://mynixos.com/nixpkgs/option/services.wivrn.config.json for an example configuration.
    };

    networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 47984 47989 47990 48010 ];
        allowedUDPPortRanges = [
            { from = 47998; to = 48000; }
            { from = 8000; to = 8010; }
        ];
    };
    services.sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
    };
    security.wrappers.sunshine = {
            owner = "root";
            group = "root";
            capabilities = "cap_sys_admin+p";
            source = "${pkgs.sunshine}/bin/sunshine";
    };
    services.avahi.publish.enable = true;
    services.avahi.publish.userServices = true;
    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
        dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
        };
        
    # Clean Quiet Boot

    programs.gamescope = {
        enable = true;
        capSysNice = true;
    };
    programs.steam.gamescopeSession.enable = true; # Integrates with programs.steam
    environment.systemPackages = with pkgs; [
        gamescope-wsi # HDR won't work without this
        steam-run
        protonup-qt

    ];
    programs.steam.extraCompatPackages = with pkgs; [
        proton-ge-bin
    ];

    # Gamescope Auto Boot from TTY (example)
    services.xserver.enable = false; # Assuming no other Xserver needed
    services.getty.autologinUser = "rdean3";

    services.greetd = {
        enable = true;
        settings = {
            default_session = {
            command = "${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f -e --xwayland-count 2 --hdr-enabled --hdr-itm-enabled -- steam -pipewire-dmabuf -gamepadui -steamdeck -steamos3 > /dev/null 2>&1";
            user = "USERNAME_HERE";
            };
        };
    };
    boot = {
        # Enable "Silent boot"
        consoleLogLevel = 3;
        initrd.verbose = false;
        kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
        ];
        # Hide the OS choice for bootloaders.
        # It's still possible to open the bootloader list by pressing any key
        # It will just not appear on screen unless a key is pressed
        loader.timeout = 0;
        plymouth = {
            enable = true;
            theme = "nixos-bgrt";
            themePackages = with pkgs; [
                nixos-bgrt-plymouth
            ];
        };
    };

}
