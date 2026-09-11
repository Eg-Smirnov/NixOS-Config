{ ... }:

{
  users.users.qbittorrent.extraGroups = [ "media" ];

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