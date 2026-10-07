{ pkgs, ... }:

{
  users.groups.reverse-tunnel = { };

  users.users.reverse-tunnel = {
    isSystemUser = true;
    description = "Restricted reverse tunnel account";
    group = "reverse-tunnel";
    shell = "${pkgs.shadow}/bin/nologin";
  };

  users.users.server = {
    isNormalUser = true;
    description = "server";
    extraGroups = [ "wheel" ];
  };

  security.sudo.wheelNeedsPassword = false;
}
