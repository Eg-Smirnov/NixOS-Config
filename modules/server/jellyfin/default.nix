{ ... }:

{
  users.users.jellyfin.extraGroups = [ "media" ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.jellyfin.unitConfig.RequiresMountsFor = [
    "/media"
  ];
}