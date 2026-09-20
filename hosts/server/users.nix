{ config, pkgs, ... }:

{
  environment.shellAliases.rebuild = "sudo nixos-rebuild switch --flake ~/NixOS-Config#server";

  users.users."server" = {
    isNormalUser = true;
    description = "server";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };
}
