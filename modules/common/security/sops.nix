{ config, pkgs, inputs, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    age = {
      keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";
    };
  };
}