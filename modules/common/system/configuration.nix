# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  
  networking.networkmanager.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Включаем поддержку постоянного хранилища
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/lib"
      "/etc/NetworkManager/system-connections"
    ];
    users.server = {
      directories = [
        ".ssh"         # <-- Вот эта строчка сохранит твою папку с ключами
        ".local/share/keyrings"
      ];
      files = [
        ".bash_history"
        "/var/lib/sops-nix/key.txt"
      ];
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    ports = [ 22 ];
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "26.05"; # Did you read the comment?
}
