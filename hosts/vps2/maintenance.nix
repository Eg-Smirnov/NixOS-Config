{ ... }:

{
  nix = {
    settings.auto-optimise-store = true;

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 3d";
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=64M
    RuntimeMaxUse=32M
  '';

  virtualisation.podman.autoPrune = {
    enable = true;
    dates = "weekly";
    flags = [ "--all" ];
  };
}
