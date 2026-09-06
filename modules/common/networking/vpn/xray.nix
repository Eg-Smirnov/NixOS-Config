{ config, pkgs, ... }:

{
  sops.secrets.vpn_config = {
    owner = "root";
    group = "root";
    mode = "0400";
  };

  environment.systemPackages = [
    pkgs.xray
  ];

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

  systemd.services.xray-routing = {
    description = "Routing for Xray full-tunnel VPN";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "xray-vpn.service"
      "sops-nix.service"
    ];

    wants = [
      "network-online.target"
    ];

    requires = [
      "xray-vpn.service"
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = pkgs.writeShellScript "xray-routing" ''
        set -euo pipefail

        VPN_CONFIG="${config.sops.secrets.vpn_config.path}"

        # Ждём появления TUN-интерфейса xray0.
        for i in $(seq 1 30); do
          if ${pkgs.iproute2}/bin/ip link show xray0 >/dev/null 2>&1; then
            break
          fi

          sleep 1
        done

        if ! ${pkgs.iproute2}/bin/ip link show xray0 >/dev/null 2>&1; then
          echo "xray0 interface did not appear"
          exit 1
        fi

        # Получаем адрес VPN-сервера из Xray-конфига.
        VPN_SERVER=$(
          ${pkgs.jq}/bin/jq -r '
            .outbounds[]
            | select(.tag == "proxy")
            | .settings.vnext[0].address
          ' "$VPN_CONFIG"
        )

        if [ -z "$VPN_SERVER" ] || [ "$VPN_SERVER" = "null" ]; then
          echo "Could not determine VPN server address from vpn_config"
          exit 1
        fi

        # Получаем текущий default route ДО изменения маршрутизации.
        DEFAULT_ROUTE=$(
          ${pkgs.iproute2}/bin/ip route show default \
            | ${pkgs.coreutils}/bin/head -n1
        )

        if [ -z "$DEFAULT_ROUTE" ]; then
          echo "Could not determine default route"
          exit 1
        fi

        DEFAULT_GATEWAY=$(
          printf '%s\n' "$DEFAULT_ROUTE" \
            | ${pkgs.gnused}/bin/sed -n 's/.* via \([^ ]*\).*/\1/p'
        )

        DEFAULT_INTERFACE=$(
          printf '%s\n' "$DEFAULT_ROUTE" \
            | ${pkgs.gnused}/bin/sed -n 's/.* dev \([^ ]*\).*/\1/p'
        )

        if [ -z "$DEFAULT_INTERFACE" ]; then
          echo "Could not determine default network interface"
          exit 1
        fi

        # Если адрес VPN-сервера уже IP — используем его.
        # Если это доменное имя — резолвим IPv4.
        if ${pkgs.iproute2}/bin/ip route get "$VPN_SERVER" >/dev/null 2>&1; then
          VPN_SERVER_IP=$VPN_SERVER
        else
          VPN_SERVER_IP=$(
            ${pkgs.glibc.bin}/bin/getent ahostsv4 "$VPN_SERVER" \
              | ${pkgs.coreutils}/bin/head -n1 \
              | ${pkgs.coreutils}/bin/cut -d' ' -f1
          )
        fi

        if [ -z "$VPN_SERVER_IP" ]; then
          echo "Could not resolve VPN server: $VPN_SERVER"
          exit 1
        fi

        # Локальная сеть всегда остаётся доступной напрямую.
        if [ -n "$DEFAULT_GATEWAY" ]; then
          ${pkgs.iproute2}/bin/ip route replace \
            192.168.0.0/16 \
            via "$DEFAULT_GATEWAY" \
            dev "$DEFAULT_INTERFACE"
        else
          ${pkgs.iproute2}/bin/ip route replace \
            192.168.0.0/16 \
            dev "$DEFAULT_INTERFACE"
        fi

        # Соединение самого Xray с VPN-сервером не должно попасть в TUN.
        if [ -n "$DEFAULT_GATEWAY" ]; then
          ${pkgs.iproute2}/bin/ip route replace \
            "$VPN_SERVER_IP"/32 \
            via "$DEFAULT_GATEWAY" \
            dev "$DEFAULT_INTERFACE"
        else
          ${pkgs.iproute2}/bin/ip route replace \
            "$VPN_SERVER_IP"/32 \
            dev "$DEFAULT_INTERFACE"
        fi

        # Full tunnel для всего остального IPv4.
        ${pkgs.iproute2}/bin/ip route replace \
          0.0.0.0/1 dev xray0

        ${pkgs.iproute2}/bin/ip route replace \
          128.0.0.0/1 dev xray0

        echo "Xray routing configured:"
        echo "  LAN: 192.168.0.0/16 -> $DEFAULT_INTERFACE"
        echo "  VPN server: $VPN_SERVER_IP -> $DEFAULT_INTERFACE"
        echo "  Internet -> xray0"
      '';

      ExecStop = pkgs.writeShellScript "xray-routing-stop" ''
        ${pkgs.iproute2}/bin/ip route del 0.0.0.0/1 dev xray0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip route del 128.0.0.0/1 dev xray0 2>/dev/null || true
      '';
    };

  };
}
