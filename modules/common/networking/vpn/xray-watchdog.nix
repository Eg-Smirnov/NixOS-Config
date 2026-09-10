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
        SYSTEMCTL="${pkgs.systemd}/bin/systemctl"

        VPN_CONFIG="${config.sops.secrets.vpn_config.path}"
        TUN="xray0"

        log() {
          echo "[xray-watchdog] $*"
        }

        while true; do

          #
          # 1. TUN должен существовать
          #
          if ! $IP link show "$TUN" >/dev/null 2>&1; then
            log "xray0 is missing -> restarting xray-vpn"
            $SYSTEMCTL restart xray-vpn.service
            sleep 10
            continue
          fi

          #
          # 2. Достаём VPN server IP из секрета
          #
          VPN_SERVER="$(
            $JQ -r '
              .outbounds[]
              | select(.protocol == "vless")
              | .settings.vnext[0].address
            ' "$VPN_CONFIG" 2>/dev/null | head -n1
          )"

          if [ -z "$VPN_SERVER" ] || [ "$VPN_SERVER" = "null" ]; then
            log "cannot determine VPN server IP from secret"
            sleep 10
            continue
          fi

          #
          # 3. КРИТИЧЕСКАЯ ПРОВЕРКА:
          #    VPN server должен идти через физический интерфейс,
          #    а НЕ через xray0.
          #
          VPN_ROUTE="$($IP route get "$VPN_SERVER" 2>/dev/null || true)"

          if ! printf '%s\n' "$VPN_ROUTE" | grep -q 'dev wlp1s0'; then
            log "VPN server $VPN_SERVER is NOT routed via wlp1s0"
            log "Current route: $VPN_ROUTE"
            log "Restarting xray-routing"

            $SYSTEMCTL restart xray-routing.service

            sleep 10
            continue
          fi

          #
          # 4. Оба половинных default route должны идти в xray0
          #
          if ! $IP route show 0.0.0.0/1 | grep -q 'dev xray0'; then
            log "0.0.0.0/1 -> xray0 is missing"
            $SYSTEMCTL restart xray-routing.service
            sleep 10
            continue
          fi

          if ! $IP route show 128.0.0.0/1 | grep -q 'dev xray0'; then
            log "128.0.0.0/1 -> xray0 is missing"
            $SYSTEMCTL restart xray-routing.service
            sleep 10
            continue
          fi

          #
          # Всё нормально
          #
          sleep 10
        done
      '';
    };
  };
}