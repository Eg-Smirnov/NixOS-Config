{ pkgs, ... }:

{
  systemd.services.flaresolverr = {
    description = "FlareSolverr";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
    ];

    wants = [
      "network-online.target"
    ];

    serviceConfig = {
      ExecStart = "${pkgs.flaresolverr}/bin/flaresolverr";

      Restart = "on-failure";
      RestartSec = 5;

      DynamicUser = true;

      StateDirectory = "flaresolverr";
      CacheDirectory = "flaresolverr";

      Environment = [
        "LOG_LEVEL=info"
        "HOST=127.0.0.1"
        "PORT=8191"

        "HOME=/var/lib/flaresolverr"
        "XDG_CACHE_HOME=/var/cache/flaresolverr"
      ];

      PrivateTmp = true;

      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
}