{
  description = "nix-config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    # Unstable nixpkgs, used only where a module needs it (e.g. Jovian/SteamOS on steammachine)
    unstable-nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Jovian-NixOS (SteamOS-like Steam Deck UI/gamescope session, used by steammachine)
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "unstable-nixpkgs";
    };
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Impermanence
    impermanence.url = "github:nix-community/impermanence";
    # Home-manager
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Mobile-nixos
    mobile-nixos = {
      url = github:pcs3rd/mobile-nixos/Lenovo-kodama;
      flake = false;
    };
    # NixOS-hardware
    #nixos-hardware.url = "github:NixOS/nixos-hardware/master";
		nixos-hardware.url = "github:8bitbuddhist/nixos-hardware?ref=surface-rust-target-spec-fix";

    # ISO builder, used for the steammachine auto-install image
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    unstable-nixpkgs,
    jovian,
    home-manager,
    impermanence,
    disko,
    mobile-nixos,
    nixos-hardware,
    nixos-generators,
    ...
  } @ inputs: let
    inherit (self) outputs;
    inherit (nixpkgs) lib;
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;

    # Generic unattended auto-install ISO builder — works for ANY host in
    # nixosConfigurations, not just one hardcoded machine. Reads the target
    # host's own architecture and disk device straight out of its already-
    # defined config, so there's nothing to duplicate per host.
    # Usage: nix build .#packages.<system>.<hostname>-installer-iso
    mkAutoInstallIso = hostname: nixos-generators.nixosGenerate {
      system = self.nixosConfigurations.${hostname}.pkgs.stdenv.hostPlatform.system;
      format = "install-iso";
      specialArgs = {
        inherit inputs outputs self hostname;
        diskDevice = self.nixosConfigurations.${hostname}.config.disko.devices.disk.system.device;
      };
      modules = [ ./base-configs/auto-installer.nix ];
    };

    # Builds one installer ISO per host, grouped under packages.<system> to
    # match each host's own architecture (so an aarch64 host gets an aarch64
    # installer, etc).
    installerIsos = lib.foldl' (acc: hostname:
      let system = self.nixosConfigurations.${hostname}.pkgs.stdenv.hostPlatform.system;
      in lib.recursiveUpdate acc {
        ${system}."${hostname}-installer-iso" = mkAutoInstallIso hostname;
      }
    ) {} (builtins.attrNames self.nixosConfigurations);
  in {
    homeConfigurations = {
      # FIXME replace with your username@hostname
      "rdean@macair" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main home-manager configuration file <
          ./home-configs/raine.nix
        ];
      };
    };
    nixosConfigurations = {
      imac = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            home-manager.nixosModules.home-manager
            ./alacarte/gnome-desktop.nix
            ./base-configs/imac.nix
            ./disko-configs/desktop.nix
            ./alacarte/grub.nix
            ./home-configs/raine.nix
            ./alacarte/tailscale.nix
            {
              networking.hostName = "imac";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      hammock = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/ham-laptop.nix
            ./disko-configs/laptop.nix
						./alacarte/ham-packages.nix
            {
              networking.hostName = "hammock";
              disko.devices.disk.system.device = "/dev/mmcblk0";
            }
        ];
      };
      sevenofnine = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/server.nix
            ./disko-configs/virtualized-sevenofnine.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
           # ./alacarte/sevenofnine-disk-mounts.nix
            {
              networking.hostName = "sevenofnine";
              #boot.loader.grub.device = "/dev/vda";
              disko.devices.disk.system.device = "/dev/vda";
            }
        ];
      };
      locutusofborg = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/generic-server.nix
            ./disko-configs/server.nix
            ./alacarte/rclone-config.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/grub.nix
            ./alacarte/nvidia.nix
            {
              networking.hostName = "locutusofborg";
              boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      air-traffic-control = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/generic-server.nix
            ./disko-configs/server.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/grub.nix
            {
              networking.hostName = "air-traffic-control";
              boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      # SteamOS-like gaming box, built on unstable-nixpkgs because Jovian-NixOS's
      # overlay (decky-loader, patched steam/gamescope) targets nixos-unstable.
      # Every other host in this flake stays on stable nixpkgs.
      steammachine = unstable-nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            jovian.nixosModules.default
            ./base-configs/steammachine.nix
            ./disko-configs/steammachine.nix
            ./alacarte/steam-jovian.nix
            ./alacarte/tailscale.nix
            {
              networking.hostName = "steammachine";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
    };
    # nix build .#packages.<system>.<hostname>-installer-iso, e.g.:
    #   nix build .#packages.x86_64-linux.steammachine-installer-iso
    # Result is in result/iso/*.iso — flash it to a USB stick and boot the
    # target machine from it. It wipes that host's configured disk and
    # installs its flake configuration completely unattended (see
    # base-configs/auto-installer.nix for the install script and its abort
    # window).
    packages = installerIsos;
  };
}
