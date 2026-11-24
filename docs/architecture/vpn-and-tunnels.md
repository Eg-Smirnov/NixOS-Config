# VPN and tunnel flows

These flows reconstruct relationships from tracked declarations. **Declared**
means a source file sets the relationship; **inference** means the direction
is derived across files. Active interfaces, routes, handshakes, tunnel health,
service health, and reachability remain **unknown**. For addresses and firewall
surface, see [networking](networking.md); for unit inventory, see [services](services.md).

## AmneziaWG cascade

1. `vps1` declares `awg-entry` for client peers. Its source-backed listen port
   is UDP `30326`, and its client subnet is `10.201.0.0/24` (**declared** in
   [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix) and
   [`hosts/vps1/awg-clients.json`](../../hosts/vps1/awg-clients.json)).
2. `vps1` declares `awg-uplink` at `10.200.0.1/30` toward
   `104.128.142.208:30326`, with client traffic selected into routing table
   `100` (**declared** in [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix)).
3. `vps2` declares `awg-exit` at `10.200.0.2/30`, accepts the uplink and client
   subnet, and NATs the interface to `ens3` (**declared** in
   [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix)).

The persistent blackhole route in table 100 is a declared fail-closed
boundary. It does not prove that the policy unit or route is active. The
server's separate full-tunnel AWG service is secret-configured and has no
tracked endpoint to document.

## Reverse SSH and exact forwards

The server declares two long-running units in
[`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix), both
connecting as `reverse-tunnel` to `103.71.20.103:22`:

- `reverse-ssh.service` requests remote loopback forward
  `127.0.0.1:22022 -> server 127.0.0.1:22`.
- `reverse-media-ssh.service` requests these remote loopback forwards:

  | `vps1` remote listener | Server-local destination | Declared consumer |
  |---:|---:|---|
  | `127.0.0.1:18096` | `127.0.0.1:8096` | Jellyfin |
  | `127.0.0.1:18989` | `127.0.0.1:8989` | Sonarr |
  | `127.0.0.1:17878` | `127.0.0.1:7878` | Radarr |
  | `127.0.0.1:19696` | `127.0.0.1:9696` | Prowlarr |
  | `127.0.0.1:18080` | `127.0.0.1:8080` | qBittorrent |

The port map is also declared in [`hosts/server/infrastructure.nix`](../../hosts/server/infrastructure.nix).
On `vps1`, [`hosts/vps1/ssh.nix`](../../hosts/vps1/ssh.nix) restricts the
`reverse-tunnel` account to remote forwarding and the listed `PermitListen`
addresses. No private key or credential is documented.

## Public media gateway

[`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix) declares
Nginx/ACME virtual hosts for:

| Hostname source | Gateway backend | Access boundary |
|---|---|---|
| `jellyfin.aboba-server.ru` | loopback `18096` | public virtual host; WebSockets enabled |
| `sonarr.aboba-server.ru` | loopback `18989` | temporary allowlist |
| `radarr.aboba-server.ru` | loopback `17878` | temporary allowlist |
| `prowlarr.aboba-server.ru` | loopback `19696` | temporary allowlist |
| `qbit.aboba-server.ru` | loopback `18080` | temporary allowlist and qBittorrent host header |

The gateway declares `arr-access-init`, `arr-access-expire.service`, and a
2-hour `arr-access-expire.timer`; `arr-open`, `arr-close`, and `arr-status` are
installed as packages. Nginx maps upstream failures to a declared 503 response.
This does not prove DNS, certificates, allowlist state, tunnel state, backend
health, or public reachability.

## Unsupported or dormant paths

Xray modules remain in source but are not imported by the supported server
entrypoint. They are not presented as a working VPN. The `wsl` target is an
abandoned legacy output and is excluded from this flow map; see
[`AGENTS.md`](../../AGENTS.md).
