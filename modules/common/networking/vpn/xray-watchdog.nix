{ config, pkgs, ... }:

{
  systemd.services.xray-watchdog = {
    description = "Watchdog for Xray full-tunnel routing";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "xray-vpn.service"
      "xray-routing.service"
      "sops-nix.service"
    ];

    wants = [
      "network-online.target"
      "xray-vpn.service"
      "xray-routing.service"
    ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "10s";

      ExecStart = pkgs.writeShellScript "xray-watchdog" ''
        set -u

        IP="${pkgs.iproute2}/bin/ip"
        JQ="${pkgs.jq}/bin/jq"
        GREP="${pkgs.gnugrep}/bin/grep"
        SYSTEMCTL="${pkgs.systemd}/bin/systemctl"

        VPN_CONFIG="${config.sops.secrets.vpn_config.path}"
        TUN="xray0"
        PHYSICAL_IF="wlp1s0"
        GATEWAY="192.168.1.1"

        log() {
          echo "[xray-watchdog] $*"
        }

        while true; do

          #
          # 1. Проверяем, что физическая сеть вообще доступна.
          #
          if ! $IP link show "$PHYSICAL_IF" >/dev/null 2>&1; then
            log "$PHYSICAL_IF is missing, waiting for network"
            sleep 10
            continue
          fi

          if ! $IP route get "$GATEWAY" 2>/dev/null | $GREP -q "dev $PHYSICAL_IF"; then
            log "Physical network is not ready, waiting"
            sleep 10
            continue
          fi

          #
          # 2. Проверяем Xray TUN.
          #
          if ! $IP link show "$TUN" >/dev/null 2>&1; then
            log "xray0 is missing -> restarting xray-vpn"
            $SYSTEMCTL restart xray-vpn.service
            sleep 10
            continue
          fi

          #
          # 3. Достаём адрес VPN-сервера из секрета.
          #
          VPN_SERVER="$(
            $JQ -r '
              .outbounds[]
              | select(.protocol == "vless")
              | .settings.vnext[0].address
            ' "$VPN_CONFIG" 2>/dev/null | head -n1
          )"

          if [ -z "$VPN_SERVER" ] || [ "$VPN_SERVER" = "null" ]; then
            log "Cannot determine VPN server from secret"
            sleep 10
            continue
          fi

          #
          # 4. КРИТИЧЕСКАЯ ПРОВЕРКА:
          #    VPN-сервер должен идти напрямую через wlp1s0.
          #
          VPN_ROUTE="$($IP route get "$VPN_SERVER" 2>/dev/null || true)"

          if ! printf '%s\n' "$VPN_ROUTE" | $GREP -q "dev $PHYSICAL_IF"; then
            log "VPN server $VPN_SERVER is NOT routed via $PHYSICAL_IF"
            log "Current route: $VPN_ROUTE"

            #
            # Физическая сеть есть, поэтому routing должен
            # суметь восстановить маршрут.
            #
            log "Restarting xray-routing"
            $SYSTEMCTL restart xray-routing.service || \
              log "xray-routing restart failed, will retry"

            sleep 10
            continue
          fi

          #
          # 5. Проверяем первый половинный default route.
          #
          if ! $IP route show 0.0.0.0/1 | $GREP -q "dev $TUN"; then
            log "0.0.0.0/1 -> $TUN is missing"
            log "Restarting xray-routing"

            $SYSTEMCTL restart xray-routing.service || \
              log "xray-routing restart failed, will retry"

            sleep 10
            continue
          fi

          #
          # 6. Проверяем второй половинный default route.
          #
          if ! $IP route show 128.0.0.0/1 | $GREP -q "dev $TUN"; then
            log "128.0.0.0/1 -> $TUN is missing"
            log "Restarting xray-routing"

            $SYSTEMCTL restart xray-routing.service || \
              log "xray-routing restart failed, will retry"

            sleep 10
            continue
          fi

          #
          # 7. Всё хорошо.
          #
          sleep 10
        done
      '';
    };
  };
}