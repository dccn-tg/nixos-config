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
        nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            disko.nixosModules.disko

            ./modules/options.nix
            ./modules/disko.nix
            ./modules/system/common.nix
            ./hosts/${hostname}

          ];
        };
    in
    {
      nixosConfigurations = {
        vm001 = mkHost "vm001";
      };
    };
}