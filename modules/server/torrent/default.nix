{ lib, ... }:

{
  users.users.qbittorrent.extraGroups = [ "media" ];

  services.qbittorrent = {
    enable = true;

    openFirewall = true;

    extraArgs = [ "--confirm-legal-notice" ];
  };

  systemd.services.qbittorrent.unitConfig.RequiresMountsFor = [
    "/media"
  ];

  systemd.services.qbittorrent.serviceConfig.PrivateUsers = lib.mkForce false;
  systemd.services.qbittorrent.serviceConfig.PrivateDevices = lib.mkForce false;
}
