{ ... }:

{
  users.groups.media = {};

  users.users.qbittorrent.extraGroups = [ "media" ];

  systemd.tmpfiles.rules = [
    "d /media/downloads 2775 root media -"
    "d /media/downloads/incomplete 2775 root media -"
    "d /media/downloads/complete 2775 root media -"
  ];

  services.qbittorrent = {
    enable = true;

    openFirewall = true;

    serverConfig = {
      LegalNotice.Accepted = true;

      Preferences = {
        Downloads = {
          SavePath = "/media/downloads/complete/";
          TempPath = "/media/downloads/incomplete/";
          TempPathEnabled = true;
        };
      };
    };
  };

  systemd.services.qbittorrent.unitConfig.RequiresMountsFor = [
    "/media"
  ];
}