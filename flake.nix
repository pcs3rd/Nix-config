{
  description = "nix-config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.05-darwin";
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    mobile-nixos = {
      url = github:pcs3rd/mobile-nixos/Lenovo-kodama;
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    disko,
    darwin,
    mobile-nixos, 
    ...
  } @ inputs: let
    inherit (self) outputs;
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
          ./home-configs/raymond.nix
        ];
      };
    };
    darwinConfigurations = {
      "a2681" = darwin.lib.darwinSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./modules/nix-core.nix
          ./modules/system.nix
          ./modules/apps.nix
          ./modules/host-users.nix
          ./darwin-alacarte/nix-conf.nix
        ];
      };
  };
    nixosConfigurations = {
      kodama = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
              (import "${mobile-nixos}/lib/configuration.nix" {
                device = "lenovo-kodama";
              })
            ./alacarte/tailscale.nix
            ./base-configs/kodama.nix
        ];
      };
      stealth = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./alacarte/tailscale.nix
            ./alacarte/grub.nix
            ./alacarte/tailscale.nix
            ./alacarte/gnome-desktop.nix
            ./base-configs/generic-mac.nix
            ./home-configs/raymond.nix
						./disko-configs/laptop.nix
           {
              networking.hostName = "stealth";
              boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      stealth-vm = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./alacarte/tailscale.nix
            ./alacarte/grub.nix
            ./alacarte/tailscale.nix
            ./alacarte/gnome-desktop.nix
            ./base-configs/generic-mac.nix
            ./home-configs/raymond.nix
						./disko-configs/laptop.nix
           {
              networking.hostName = "stealth-vm";
              boot.loader.grub.device = "/dev/vda";
              disko.devices.disk.system.device = "/dev/vda";
            }
        ];
      };
      sevenofnine = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/generic-server.nix
            ./disko-configs/server.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/grub.nix
            ./alacarte/sevenofnine-disk-mounts.nix
            {
              networking.hostName = "sevenofnine";
              boot.loader.grub.device = "/dev/nvme0n1";
              disko.devices.disk.system.device = "/dev/nvme0n1";
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
            {
              networking.hostName = "locutusofborg";
              boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      router = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/bl460c.nix
            ./disko-configs/backplane.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/grub.nix
            {
              boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
    };

    kodama-disk-image =
      (import "${mobile-nixos}/lib/eval-with-configuration.nix" {
        configuration = [ (import ./base-configs/kodama.nix) ];
        device = "lenovo-kodama";
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
      }).outputs.disk-image;
     #nix build .#pinephone-disk-image --impure
  };
}
