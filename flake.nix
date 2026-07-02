{
  description = "Hong's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs = { self, nixpkgs, ... }:

  let
    system = "x86_64-linux";

    mkHost = hostFile:
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          hostFile
        ];
      };

    hostFiles = builtins.readDir ./hosts;

    hostNames = builtins.attrNames (
      nixpkgs.lib.filterAttrs
        (name: type: type == "regular" && builtins.match ".*\\.nix" name != null)
        hostFiles
    );

  in {
    nixosConfigurations =
      builtins.listToAttrs (
        map (file: {
          name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
          value = mkHost (./hosts + "/${file}");
        }) hostNames
      );
  };
}