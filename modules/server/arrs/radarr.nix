{ ... }:

{
  users.users.radarr.extraGroups = [ "media" ];

  services.radarr = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.radarr.unitConfig.RequiresMountsFor = [
    "/media"
  ];
}