# Role axis (install-args `role`). `geek` is `norm` plus development features.
{ self, ... }:

{
  flake.modules.nixos.role-norm = { pkgs, ... }: {
    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
  };

  flake.modules.nixos.role-geek = { pkgs, ... }: {
    imports = [ self.modules.nixos.role-norm ];

    environment.systemPackages = with pkgs;[ 
      vscode
      fastfetch
    ];
    local.allowedUnfree = [ "vscode" ];

    programs.zsh.interactiveShellInit = "fastfetch";

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
