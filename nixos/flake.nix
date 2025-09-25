{
  description = "NixOS configuration";

  # All inputs for the system
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          inputs.disko.nixosModules.disko
        ];
        specialArgs = {inherit inputs;};
      };
  in {
    nixosConfigurations = {
      apps-vm = mkSystem "x86_64-linux" "apps-vm";
      infrastructure-vm = mkSystem "x86_64-linux" "infrastructure-vm";
      media-downloader-vm = mkSystem "x86_64-linux" "media-downloader-vm";
      gpu-workloads-vm = mkSystem "x86_64-linux" "gpu-workloads-vm";
      dmz-vm = mkSystem "x86_64-linux" "dmz-vm";
      myrctf-vm = mkSystem "x86_64-linux" "myrctf-vm";
    };
  };
}