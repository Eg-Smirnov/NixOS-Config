{ config, pkgs, ... }:

{
  users.users."server" = {
    isNormalUser = true;
    description = "server";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };
}