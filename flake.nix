{
  description = "nix-config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    # Impermanence
    impermanence.url = "github:nix-community/impermanence";
    # Home-manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    disko,
    mobile-nixos, 
    nixos-hardware,
    companion,
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
            ./base-configs/virtualized-server.nix
            ./disko-configs/virtualized-sevenofnine.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            #./alacarte/sevenofnine-disk-mounts.nix
            {
              networking.hostName = "sevenofnine";
              #boot.loader.grub.device = "/dev/xvda";
              disko.devices.disk.system.device = "/dev/xvda";
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
    };
  };
}
