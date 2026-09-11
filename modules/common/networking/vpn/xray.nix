{ config, pkgs, ... }:

{
  sops.secrets.vpn_config = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  environment.systemPackages = [
    pkgs.xray
  ];

  imports = [
    ./xray-vpn.nix
    ./xray-routing.nix
    ./xray-watchdog.nix
  ];
}