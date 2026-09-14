{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ./networking.nix
    ./users.nix
    ./ssh.nix
    ../../modules/vps/3x-ui.nix
  ];

  networking.hostName = "vps1";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  services.xserver.enable = false;

  services.threeXui.enable = true;

  system.stateVersion = "26.05";
}
