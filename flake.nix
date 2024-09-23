{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    impermanence,
    disko,
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
    nixosConfigurations = {
      bladeworker01 = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/cluster-base.nix
            ./disko-configs/server.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/grub.nix
            ./alacarte/server-hardenning.nix
            {
              networking.hostName = "bladeworker01";
              #boot.loader.grub.device = "/dev/sda";
              disko.devices.disk.system.device = "/dev/sda";
            }
        ];
      };
      experimental = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/generic-server.nix
            ./disko-configs/server.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
            ./alacarte/virtio.nix
            ./alacarte/grub.nix
            ./alacarte/server-hardenning.nix
            {
              networking.hostName = "experimental";
              #boot.loader.grub.device = "/dev/vda";
              disko.devices.disk.system.device = "/dev/vda";
            }
        ];
      };
    };
  };
}