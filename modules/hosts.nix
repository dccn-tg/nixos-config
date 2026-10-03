# Builds one nixosConfiguration per directory in hosts/ that has an install-args.nix.
#
# A host is: base + storage + <hardware> + <desktop> + <role> [+ nvidia mixin] [+ secureboot],
# selected by hosts/<name>/install-args.nix.
{ inputs, self, lib, ... }:

let
  hostsDir = ../hosts;

  hostNames = lib.attrNames (lib.filterAttrs
    (name: type: type == "directory" && builtins.pathExists (hostsDir + "/${name}/install-args.nix"))
    (builtins.readDir hostsDir));

  mkHost = name:
    let
      host = {
        nvidia = false;
        secureboot = false;
        desktop = "gnome";
        role = "norm";
      } // import (hostsDir + "/${name}/install-args.nix");

      nixosModules = self.modules.nixos;
    in
    inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit host; };

      modules = [
        inputs.disko.nixosModules.disko
        nixosModules.base
        nixosModules.storage
        nixosModules."hw-${host.hardware}"
        nixosModules."desktop-${host.desktop}"
        nixosModules."role-${host.role}"
        (hostsDir + "/${name}/hardware.nix")
      ] ++ lib.optional host.nvidia nixosModules.hw-nvidia
        ++ lib.optionals host.secureboot [
          inputs.lanzaboote.nixosModules.lanzaboote
          nixosModules.secureboot
        ];
    };
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations = lib.genAttrs hostNames mkHost;
}
