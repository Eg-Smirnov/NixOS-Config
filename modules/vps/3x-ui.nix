{ config, lib, ... }:

let
  cfg = config.services.threeXui;
in
{
  options.services.threeXui = {
    enable = lib.mkEnableOption "the 3x-ui container";

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/mhsanaei/3x-ui@sha256:82552eab7b8f43eb5346ef75c1004cc68042db1864cbafc4cc0bd0515dea3640";
      description = "Pinned upstream 3x-ui v3.2.6 amd64 image.";
    };

    stateDirectory = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/3x-ui";
      description = "Persistent host directory for the database and certificates.";
    };

    enableFail2ban = lib.mkEnableOption "3x-ui's container-managed Fail2ban";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;
    virtualisation.oci-containers.backend = "podman";

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDirectory} 0750 root root -"
      "d ${cfg.stateDirectory}/db 0750 root root -"
      "d ${cfg.stateDirectory}/cert 0750 root root -"
    ];

    virtualisation.oci-containers.containers."3x-ui" = {
      image = cfg.image;
      autoStart = true;

      volumes = [
        "${cfg.stateDirectory}/db:/etc/x-ui"
        "${cfg.stateDirectory}/cert:/root/cert"
      ];

      extraOptions = [ "--network=host" ]
        ++ lib.optionals cfg.enableFail2ban [
          "--cap-add=NET_ADMIN"
          "--cap-add=NET_RAW"
        ];

      environment = lib.optionalAttrs (!cfg.enableFail2ban) {
        XUI_ENABLE_FAIL2BAN = "false";
      };
    };
  };
}
