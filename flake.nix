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
    disko,
    ...
  } @ inputs: let
    inherit (self) outputs;
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
            ./alacarte/prefered-server-env.nix
            ./alacarte/tailscale.nix
            ./alacarte/docker.nix
        ];
      };
    };
  };
}