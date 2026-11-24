# Services and automation architecture

This inventory covers source imported by `server`, `vps1`, and `vps2`. A unit or
module being declared or enabled is not runtime evidence that it is running,
healthy, reachable, or has completed a timer action. Labels are **declared**
unless marked **inference** or **unknown**. See [system overview](system-overview.md),
[VPN and tunnels](vpn-and-tunnels.md), and [runtime diagnostics](../operations/runtime-diagnostics.md).

## Server service matrix

| Unit or service | Source declaration | Exact source-backed behavior | Boundary |
|---|---|---|---|
| `jellyfin.service` | [`modules/server/jellyfin/default.nix`](../../modules/server/jellyfin/default.nix) | Enabled, firewall opening requested, user joins `media`, requires `/media` | The module does not set an exact listen port; runtime socket/health **unknown** |
| `qbittorrent.service` | [`modules/server/torrent/default.nix`](../../modules/server/torrent/default.nix) | Enabled, firewall opening requested, user joins `media`, requires `/media`; `PrivateUsers` and `PrivateDevices` are forced false | Media data and service state are user-data boundaries |
| `sonarr.service` / `radarr.service` | [`modules/server/arrs/sonarr.nix`](../../modules/server/arrs/sonarr.nix), [`radarr.nix`](../../modules/server/arrs/radarr.nix) | Enabled, firewall opening requested, users join `media`, each requires `/media` | Exact local listen ports are not set in these modules |
| `prowlarr.service` | [`modules/server/arrs/prowlarr.nix`](../../modules/server/arrs/prowlarr.nix) | Enabled and firewall opening requested | User, mount, and exact port are not set in this module |
| `flaresolverr.service` | [`modules/server/arrs/flaresolverr.nix`](../../modules/server/arrs/flaresolverr.nix) | Dynamic user; loopback `127.0.0.1:8191`; state/cache directories; wants `network-online.target` | Loopback binding is source-declared; runtime state **unknown** |
| `reverse-ssh.service` | [`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix) | Persistent reverse SSH to `vps1:22`; remote loopback `127.0.0.1:22022` forwards to server SSH `127.0.0.1:22` | Secret-backed key and connection state are excluded/unknown |
| `reverse-media-ssh.service` | [`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix) | Persistent remote loopback forwards `18096→8096`, `18989→8989`, `17878→7878`, `19696→9696`, `18080→8080` | The forward declarations do not prove media services listen |
| `night-sleep.service` / `night-sleep.timer` | [`modules/server/night-sleep.nix`](../../modules/server/night-sleep.nix) | Checks Jellyfin activity during the declared night window; may suspend when idle; requires `jellyfin.service` | Timer execution, activity, and suspend state **unknown**; owner gate before investigation/remediation |
| `morning-wake.service` / `.timer` | [`modules/server/night-sleep.nix`](../../modules/server/night-sleep.nix) | No-op service; RTC wake timer declared for `08:30:00` with `WakeSystem = true` | Firmware/RTC behavior and execution **unknown** |
| `thermal-observer.service` | [`modules/server/thermal-observer.nix`](../../modules/server/thermal-observer.nix) | Root collector samples every 10 seconds and writes daily CSV under `/var/lib/thermal-observer`; starts after `local-fs.target` | Diagnostic output can disclose process names and host data; do not export unredacted logs |

The media module creates `/media/downloads/{incomplete,complete}`,
`/media/series`, and `/media/movies` for group `media` (**declared** in
[`modules/server/media.nix`](../../modules/server/media.nix)). `/media` is user
data, not disposable cache.

## VPS gateway and VPN units

| Host/unit or service | Source declaration | Exact source-backed behavior | Boundary |
|---|---|---|---|
| `amneziawg.service` | [`modules/server/vpn/amneziawg.nix`](../../modules/server/vpn/amneziawg.nix) | Server full-tunnel AWG service reads a secret config; `amneziawg-watchdog.timer` is scheduled every 30 seconds after boot | Endpoint, route, handshake, and watchdog activity **unknown** |
| `awg-client-routing-policy.service` | [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix) | Oneshot policy installs table-100 blackhole default and rule for `10.201.0.0/24`; ordered before entry/uplink units | A declaration is not current route evidence |
| `wireguard-awg-entry` / `wireguard-awg-uplink` | [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix) | NixOS-generated interface units for `awg-entry` and `awg-uplink`; client entry listens on source-backed UDP `30326`, uplink targets `vps2:30326` | Generated unit state and handshakes **unknown** |
| `wireguard-awg-exit` | [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix) | NixOS-generated unit for `awg-exit`; IPv4 forwarding and NAT to `ens3` declared | Runtime NAT/routes **unknown** |
| `nginx.service` | [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) | Nginx/ACME virtual hosts proxy the five reverse-media loopback ports; upstream failures map to 503 | DNS, TLS, listeners, tunnel, and backend health **unknown** |
| `arr-access-init.service` | [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) | Required before Nginx; writes a closed allowlist with permanent source `104.128.142.208` | Initial state/execution **unknown** |
| `arr-access-expire.service` / `.timer` | [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) | One-shot closes temporary access; timer is armed for `2h` after opening | Timer state **unknown**; access changes require owner approval |
| VPS2 maintenance policies | [`hosts/vps2/maintenance.nix`](../../hosts/vps2/maintenance.nix) | Daily Nix GC older than 3 days, journald limits `64M`/`32M`, weekly Podman auto-prune with `--all` | Policy execution and data-retention effects **unknown**; cleanup is owner-gated |

The exact remote-to-local media forward table is maintained in
[VPN and tunnels](vpn-and-tunnels.md), not duplicated in this table.

## Dormant and excluded source

- The server auto-update aggregate exists under [`modules/server/auto-update`](../../modules/server/auto-update)
  but its import is commented out in [`hosts/server/default.nix`](../../hosts/server/default.nix).
- Xray modules are source-present but not imported by the supported server
  entrypoint and are not a current VPN/service path.
- Legacy 3x-ui persistence is not an active service declaration in the current
  host entrypoints; historical runbooks are not current procedures.
- `wsl` is an abandoned legacy target and is excluded. No runtime claim follows
  from any excluded or dormant source.

No cleanup, restart, activation, troubleshooting, recovery, or secret-handling
procedure belongs in this inventory. Use the [operations pages](../operations/deployment.md)
with their explicit owner gates.
