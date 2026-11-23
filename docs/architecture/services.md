# Services and automation architecture

This inventory describes tracked source declarations for `server`, `vps1`, and
`vps2`. **Declared** means configured in source; **inference** means a relation
derived from those declarations; **owner-stated**, **observed**, and **unknown**
are separate evidence states. A module or unit declaration does not prove that
the service is active, healthy, reachable, or that a timer has executed.

## Service matrix

| Host | Service/domain | Source declaration | User/group, paths, ports and triggers | Risk/boundary |
|---|---|---|---|---|
| `server` | Jellyfin | [`modules/server/jellyfin/default.nix`](../../modules/server/jellyfin/default.nix) | service user `jellyfin` receives group `media`; requires `/media`; firewall opening is declared, exact port is **not declared here** | `/media` is user data; runtime health/reachability **unknown** |
| `server` | qBittorrent | [`modules/server/torrent/default.nix`](../../modules/server/torrent/default.nix) | user `qbittorrent` receives `media`; requires `/media`; firewall opening declared, exact port not declared here | media data and service sandbox settings are source boundaries |
| `server` | Sonarr/Radarr | [`modules/server/arrs/sonarr.nix`](../../modules/server/arrs/sonarr.nix), [`radarr.nix`](../../modules/server/arrs/radarr.nix) | users `sonarr`/`radarr` receive `media`; each requires `/media`; firewall opening declared, exact ports not declared here | media data; active state unknown |
| `server` | Prowlarr | [`modules/server/arrs/prowlarr.nix`](../../modules/server/arrs/prowlarr.nix) | service enable and firewall opening declared; user, mount, and exact port not declared in this module | runtime and dependency health unknown |
| `server` | FlareSolverr | [`modules/server/arrs/flaresolverr.nix`](../../modules/server/arrs/flaresolverr.nix) | dynamic user; loopback `127.0.0.1:8191`; starts after/wants `network-online.target`; state/cache directories declared | local-only source binding; active state unknown |
| `server` | Night sleep / morning wake | [`modules/server/night-sleep.nix`](../../modules/server/night-sleep.nix) | `night-sleep` wants/after `jellyfin.service`; timers run during the declared night window and at 08:30; source checks recent Jellyfin activity and declares suspend effect | availability impact; timer execution and sleep state unknown |
| `server` | Thermal observer | [`modules/server/thermal-observer.nix`](../../modules/server/thermal-observer.nix) | root service, state directory `/var/lib/thermal-observer`, 10-second sampling, starts after `local-fs.target` | diagnostic data and host resource access; runtime collection unknown |
| `vps1` | Nginx/ACME media gateway | [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) | Nginx and ACME declarations; proxies configured media remote ports; gateway uses `/run/arr-access` allowlist | public TLS/backend boundary; reachability and certificate state unknown |
| `vps1` | Temporary Arr access | [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) | `arr-access-init` precedes Nginx; `arr-access-expire.timer` closes temporary access after 2h | access-control availability impact; timer execution unknown |
| `vps2` | Maintenance | [`hosts/vps2/maintenance.nix`](../../hosts/vps2/maintenance.nix) | daily Nix GC policy, journald caps, weekly Podman auto-prune | data-retention effects are declarations, not execution evidence |

## Data and dependency boundaries

The server media modules share the `media` group and `/media` mount. The
gateway relationship `vps1 → reverse tunnel → server media` is an **inference**
from [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix),
[`hosts/server/infrastructure.nix`](../../hosts/server/infrastructure.nix), and
the reverse-SSH module. It does not prove an active backend.

Night-sleep depends on Jellyfin's local session endpoint and a secret consumer,
but this page records neither secret values nor private input contents. The
thermal observer writes diagnostic CSV state under its declared state directory.
VPS2 maintenance policies are source declarations; actual retention and prune
execution are **unknown**.

## Dormant or excluded source

The server auto-update aggregate exists in source but is commented out of the
supported `hosts/server/default.nix` imports; its active status is therefore
not declared. Xray modules are not a supported current VPN/service. The `wsl`
output remains an abandoned legacy target and is excluded from this inventory.

No cleanup, restart, activation, troubleshooting, recovery, or other
operational procedure belongs in this document.
