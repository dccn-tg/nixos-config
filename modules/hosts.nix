# Builds one nixosConfiguration per class: <model>-<desktop>-<role>[-sb].
#
# A class is: base + storage + hw-<model> + desktop-<desktop> + role-<role> + auto-update [+ secureboot for the -sb variant].
# Nothing is machine specific; the hostname comes from /etc/hostname (see scripts/install.sh).
{ inputs, self, lib, ... }:

let
  models = {
    vm = { diskDevice = "/dev/vda"; rootSize = "10G"; swapSize = "4G"; };
    latitude5491 = { diskDevice = "/dev/sda"; rootSize = "100G"; swapSize = "8G"; };
    precision5560 = { diskDevice = "/dev/nvme0n1"; rootSize = "100G"; swapSize = "16G"; };
  };
  desktops = [ "gnome" "kde" "sway" ];
  roles = [ "norm" "geek" ];

  mkClass = { model, desktop, role, secureboot }:
    let
      class = "${model}-${desktop}-${role}${lib.optionalString secureboot "-sb"}";
      host = models.${model} // { inherit class model desktop role secureboot; };
      nixosModules = self.modules.nixos;
    in
    lib.nameValuePair class (inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit host; };
      modules = [
        inputs.disko.nixosModules.disko
        nixosModules.base
        nixosModules.storage
        nixosModules."hw-${model}"
        nixosModules."desktop-${desktop}"
        nixosModules."role-${role}"
        nixosModules.auto-update
      ] ++ lib.optionals secureboot [
        inputs.lanzaboote.nixosModules.lanzaboote
        nixosModules.secureboot
      ];
    });
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  systems = [ "x86_64-linux" ];

  flake.nixosConfigurations = lib.listToAttrs (map mkClass (lib.cartesianProduct {
    model = lib.attrNames models;
    desktop = desktops;
    role = roles;
    secureboot = [ false true ];
  }));
}
