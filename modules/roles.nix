# Role axis (install-args `role`). `geek` is `norm` plus development features.
{ self, ... }:

{
  flake.modules.nixos.role-norm = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      firefox
    ];

    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
  };

  flake.modules.nixos.role-geek = {
    imports = [ self.modules.nixos.role-norm ];

    # virtualization tools
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;

    # container tools
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
