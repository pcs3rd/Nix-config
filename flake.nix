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
      bladeworker = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/cluster-base.nix
            ./disko-configs/cluster-base.nix
            ./alacarte/prefered-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
        ];
      };
      experimental = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
            ./base-configs/generic-server.nix
            ./disko-configs/standalone.nix
            ./alacarte/preferred-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
        ];
      };
    };
  };
}