{
  description = "My NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, ... }:
    let
      system = "x86_64-linux";

      mkHost = hostname:

        let
          host = import ./hosts/${hostname}/args.nix;
        in
          nixpkgs.lib.nixosSystem {
            inherit system;

            specialArgs = {
              inherit host;
            };

            modules = [
              disko.nixosModules.disko

              ./modules/options.nix
              ./modules/disko.nix
              ./modules/system/common.nix
              ./hosts/${hostname}/hardware.nix
              ./profiles/${host.profile}.nix
            ];
          };
    in
    {
      nixosConfigurations = {
        vm001 = mkHost "vm001";
      };
    };
}