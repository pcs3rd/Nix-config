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
    # Bitfocus Companion modules
    companion.url = "github:noblepayne/bitfocus-companion-flake";
    # ISO builder, used for the steammachine auto-install image
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # nix-darwin, so this Mac can build the (x86_64-linux) installer ISO via
    # nix-darwin's built-in Linux builder VM
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
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
    companion,
    nixos-generators,
    nix-darwin,
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
    darwinConfigurations = {
      # nix.linux-builder.enable in darwin/base-config.nix gives this Mac a
      # local Linux VM builder, so `nix build .#packages.x86_64-linux.<name>`
      # (e.g. steammachine-installer-iso) works directly from macOS.
      "raymonds-macbook-air" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {
          inherit inputs outputs;
          hostname = "raymonds-macbook-air";
          username = "rdean3";
        };
        modules = [
          ./darwin/base-config.nix
          ./darwin/rdean3.nix
        ];
      };
    };
    nixosConfigurations = {
      imac = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            companion.nixosModules.default
            {
              programs.companion.enable = true;
              programs.companion.runAsService = true;
              programs.companion.user = "1000";
              programs.companion.group = "users";
            }
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
    # Build with: nix build .#steammachine-installer-iso
    # Result is in result/iso/*.iso — flash it to a USB stick and boot the
    # target machine from it. It wipes /dev/sda and installs the
    # "steammachine" config completely unattended (see
    # base-configs/steammachine-installer.nix for the install script and its
    # abort window).
    packages.x86_64-linux.steammachine-installer-iso = nixos-generators.nixosGenerate {
      system = "x86_64-linux";
      format = "install-iso";
      specialArgs = {inherit inputs outputs self;};
      modules = [
        ./base-configs/steammachine-installer.nix
      ];
    };
  };
}
