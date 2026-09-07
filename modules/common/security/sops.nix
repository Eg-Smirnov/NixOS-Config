{ config, pkgs, inputs, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    age = {
      keyFile = "/home/server/.config/sops/age/keys.txt";
    };
  };
}