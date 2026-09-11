{ ... }:

{
  users.groups.media = {};

  systemd.tmpfiles.rules = [
    "d /media/downloads 2775 root media -"
    "d /media/downloads/incomplete 2775 root media -"
    "d /media/downloads/complete 2775 root media -"

    "d /media/series 2775 root media -"
    "d /media/movies 2775 root media -"
  ];
}