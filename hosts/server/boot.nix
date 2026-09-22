{ config, pkgs, ... }:

{

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "amdgpu.dc=0" "systemd.mask=tpm2.target" ];

  # Configure keymap in X11
  # services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  
  system.stateVersion = "26.05"; # Did you read the comment?
}
