{ infrastructure, lib, pkgs, ... }:

let
  gateway = infrastructure.vps.mediaGateway;
  media = gateway.services;

  stateDirectory = "/run/arr-access";
  allowlistPath = "${stateDirectory}/nginx-allow.conf";
  sourceIpPath = "${stateDirectory}/source-ip";

  unavailableLocation = {
    extraConfig = ''
      internal;
      default_type text/html;
      add_header Retry-After 300 always;
      return 503 '<!doctype html><html lang="ru"><meta charset="utf-8"><title>Сервер недоступен</title><style>body{font:18px system-ui;max-width:45rem;margin:15vh auto;padding:0 1.5rem;line-height:1.5}</style><h1>Домашний сервер сейчас спит</h1><p>Или временно недоступен. Штатное пробуждение — в 08:30 по московскому времени.</p></html>';
    '';
  };

  mkProxyHost = {
    remotePort,
    restricted ? false,
    webSockets ? false,
    qbittorrent ? false,
  }: {
    enableACME = true;
    forceSSL = true;

    extraConfig = ''
      proxy_intercept_errors on;
      error_page 502 503 504 =503 @backend-unavailable;
    '';

    locations = {
      "/" = {
        proxyPass = "http://127.0.0.1:${toString remotePort}";
        proxyWebsockets = webSockets;
        extraConfig = lib.concatStringsSep "\n" (
          [
            "proxy_read_timeout 3600s;"
            "proxy_send_timeout 3600s;"
          ]
          ++ lib.optional restricted "include ${allowlistPath};"
          ++ lib.optionals qbittorrent [
            "proxy_set_header Host 127.0.0.1:${toString media.qbittorrent.localPort};"
            "proxy_set_header X-Forwarded-Host $host;"
          ]
        );
      };

      "@backend-unavailable" = unavailableLocation;
    };
  };

  writeClosedAllowlist = pkgs.writeShellScript "write-closed-arr-allowlist" ''
    set -eu
    install -d -m 0755 ${stateDirectory}
    temporary="$(${pkgs.coreutils}/bin/mktemp ${stateDirectory}/nginx-allow.XXXXXX)"
    printf '%s\n' 'deny all;' > "$temporary"
    chmod 0644 "$temporary"
    mv -f "$temporary" ${allowlistPath}
    rm -f ${sourceIpPath}
  '';

  arrOpen = pkgs.writeShellApplication {
    name = "arr-open";
    runtimeInputs = [ pkgs.coreutils pkgs.python3 pkgs.sudo pkgs.systemd ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        if [ -z "''${SSH_CONNECTION:-}" ]; then
          echo "arr-open must be run through an SSH session" >&2
          exit 2
        fi
        source_ip="$(printf '%s\n' "$SSH_CONNECTION" | cut -d ' ' -f 1)"
        exec sudo "$0" "$source_ip"
      fi

      if [ "$#" -ne 1 ]; then
        echo "usage: arr-open <source-ip>" >&2
        exit 2
      fi

      source_ip="$1"
      python3 - "$source_ip" <<'PY'
      import ipaddress
      import sys

      ipaddress.ip_address(sys.argv[1])
      PY

      install -d -m 0755 ${stateDirectory}
      temporary="$(mktemp ${stateDirectory}/nginx-allow.XXXXXX)"
      printf 'allow %s;\ndeny all;\n' "$source_ip" > "$temporary"
      chmod 0644 "$temporary"
      mv -f "$temporary" ${allowlistPath}
      printf '%s\n' "$source_ip" > ${sourceIpPath}
      chmod 0644 ${sourceIpPath}

      if ! systemctl reload nginx.service; then
        ${writeClosedAllowlist}
        systemctl stop arr-access-expire.timer
        systemctl reload nginx.service || true
        echo "nginx validation failed; access remains closed" >&2
        exit 1
      fi

      systemctl restart arr-access-expire.timer
      echo "Temporary access for $source_ip is open for 2 hours"
    '';
  };

  arrClose = pkgs.writeShellApplication {
    name = "arr-close";
    runtimeInputs = [ pkgs.coreutils pkgs.sudo pkgs.systemd ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0"
      fi

      systemctl stop arr-access-expire.timer
      ${writeClosedAllowlist}
      systemctl reload nginx.service
      echo "Temporary access is closed"
    '';
  };

  arrStatus = pkgs.writeShellApplication {
    name = "arr-status";
    runtimeInputs = [ pkgs.coreutils pkgs.systemd ];
    text = ''
      if [ ! -s ${sourceIpPath} ]; then
        echo "Temporary access is closed"
        exit 0
      fi

      source_ip="$(cat ${sourceIpPath})"
      next_elapse="$(systemctl show arr-access-expire.timer --property=NextElapseUSecRealtime --value)"
      echo "Temporary access is open for $source_ip until $next_elapse"
    '';
  };
in
{
  security.acme = {
    acceptTerms = true;
    defaults.email = gateway.acmeEmail;
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      ${media.jellyfin.hostName} = mkProxyHost {
        inherit (media.jellyfin) remotePort;
        webSockets = true;
      };
      ${media.sonarr.hostName} = mkProxyHost {
        inherit (media.sonarr) remotePort;
        restricted = true;
        webSockets = true;
      };
      ${media.radarr.hostName} = mkProxyHost {
        inherit (media.radarr) remotePort;
        restricted = true;
        webSockets = true;
      };
      ${media.prowlarr.hostName} = mkProxyHost {
        inherit (media.prowlarr) remotePort;
        restricted = true;
        webSockets = true;
      };
      ${media.qbittorrent.hostName} = mkProxyHost {
        inherit (media.qbittorrent) remotePort;
        restricted = true;
        qbittorrent = true;
        webSockets = true;
      };
    };
  };

  systemd.services = {
    arr-access-init = {
      description = "Initialize the temporary media administration allowlist";
      requiredBy = [ "nginx.service" ];
      before = [ "nginx.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = writeClosedAllowlist;
        RemainAfterExit = true;
      };
    };

    arr-access-expire = {
      description = "Close temporary media administration access";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${arrClose}/bin/arr-close";
      };
    };
  };

  systemd.timers.arr-access-expire = {
    description = "Expire temporary media administration access after two hours";
    timerConfig = {
      OnActiveSec = "2h";
      AccuracySec = "1s";
      Unit = "arr-access-expire.service";
    };
  };

  environment.systemPackages = [ arrOpen arrClose arrStatus ];
}
