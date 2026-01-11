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
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Mobile-nixos
    mobile-nixos = {
      url = github:pcs3rd/mobile-nixos/Lenovo-kodama;
      flake = false;
    };
    # NixOS-hardware
    inputs.nixos-hardware.url = "github:NixOS/nixos-hardware/master";

  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    disko,
    mobile-nixos, 
    nixos-hardware,
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
          ./home-configs/raymond.nix
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
      macaw = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./alacarte/cosmic.nix
            ./base-configs/generic-mac.nix
            ./disko-configs/laptop.nix
            {
              networking.hostName = "macaw";
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
      stealth = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            nixos-hardware.nixosModules.microsoft-surface-pro-intel
            ./base-configs/laptop-surface.nix
            ./disko-configs/laptop.nix
						./alacarte/ham-packages.nix
            ./alacarte/gnome-desktop.nix
            {
              networking.hostName = "stealth";
              disko.devices.disk.system.device = "/dev/nvme0n1";
            }
        ];
      };
      steam_machine = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./alacarte/tailscale.nix
            ./base-configs/desktop.nix
            ./disko-configs/desktop.nix
            ./alacarte/steam-radeon.nix
            {
              users.mutableUsers = true;                                          
              networking.hostName = "steam_machine";
              disko.devices.disk.system.device = "/dev/sda";
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


      dev-server = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/arm-server.nix
            ./disko-configs/dev-server.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/grub.nix
            {
              networking.hostName = "dev-server";
              boot.loader.grub.device = "/dev/vda";
              disko.devices.disk.system.device = "/dev/vda";
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
