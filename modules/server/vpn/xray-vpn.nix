{ config, pkgs, ... }:

{
  systemd.services.xray-vpn = {
    description = "Xray full-tunnel VPN";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "sops-nix.service"
    ];

    wants = [
      "network-online.target"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart =
        "${pkgs.xray}/bin/xray run -format json -config ${config.sops.secrets.vpn_config.path}";

      Restart = "on-failure";
      RestartSec = "5s";

      AmbientCapabilities = [
        "CAP_NET_ADMIN"
      ];

      CapabilityBoundingSet = [
        "CAP_NET_ADMIN"
      ];

      NoNewPrivileges = true;
    };
  };
}