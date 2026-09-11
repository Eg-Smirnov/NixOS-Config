{ ... }:

{
  users.users.sonarr.extraGroups = [ "media" ];

  services.sonarr = {
    enable = true;

    openFirewall = true;
  };

  systemd.services.sonarr.unitConfig.RequiresMountsFor = [
    "/media"
  ];
}