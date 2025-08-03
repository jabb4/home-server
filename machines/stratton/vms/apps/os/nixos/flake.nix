{
  description = "NixOS configuration";

  # All inputs for the system
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # All outputs for the system (configs)
  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    mkSystem = system: hostname: let
    in
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {networking.hostName = hostname;}
          (./. + "/hosts/${hostname}/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager.useUserPackages = true;
            home-manager.useGlobalPkgs = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.nixos = ./. + "/hosts/${hostname}/user.nix";
          }
        ];
        specialArgs = {inherit inputs;};
      };
  in {
    nixosConfigurations = {
      apps = mkSystem "x86_64-linux" "apps";
    };
  };
}
