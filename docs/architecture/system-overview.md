# System overview

## Evidence boundary

This is a source-based overview of the supported NixOS outputs. **Declared**
means a tracked source file sets the relationship; **inference** means the
relationship is reconstructed from those declarations. **Observed** runtime
state is not collected here. Active generations, service health, routes,
reachability, DNS/TLS, mounts, and backup status are **unknown**.

For detail, use the linked pages rather than treating this overview as a second
network or service inventory: [hosts](hosts.md), [networking](networking.md),
[VPN and tunnels](vpn-and-tunnels.md), [services](services.md), [storage and
boot](storage-and-boot.md), and [security and secrets](security-and-secrets.md).

## Supported outputs

| Output | Entrypoint | Source-declared responsibility |
|---|---|---|
| `server` | [`hosts/server/default.nix`](../../hosts/server/default.nix) | Home host with NetworkManager/local networking, secret-backed AmneziaWG, reverse SSH/media tunnels, media services, power/sleep/thermal automation, and the agent workspace (**declared**) |
| `vps1` | [`hosts/vps1/default.nix`](../../hosts/vps1/default.nix) | Public ingress, AmneziaWG entry/uplink, fail-closed client routing, restricted SSH forwarding endpoint, Nginx/ACME media gateway, and private-secret consumers (**declared/inference**) |
| `vps2` | [`hosts/vps2/default.nix`](../../hosts/vps2/default.nix) | AmneziaWG egress/NAT, static networking, persistence, boot, and maintenance policies (**declared**) |

The outputs are registered in [`flake.nix`](../../flake.nix). This table does
not establish which output is currently deployed.

## Entrypoints and import graph

The flake passes `infrastructure` and a private `secrets` input to `server` and
`vps1`; `vps2` receives `secrets` only. The source-level graph is:

```text
flake.nix
├── nixosConfigurations.server
│   └── hosts/server/default.nix
│       ├── host: hardware, sops, ssh, known-hosts, impermanence, boot, users
│       ├── host: agent-workspace, networking
│       └── modules: AmneziaWG, reverse SSH, git, media, torrent, Arr, Jellyfin,
│                   power, night-sleep, thermal-observer
├── nixosConfigurations.vps1
│   └── hosts/vps1/default.nix
│       ├── host: hardware, disko, impermanence, boot, networking, wireguard,
│       │         users, ssh
│       └── modules: media-gateway, git, private-secrets
└── nixosConfigurations.vps2
    └── hosts/vps2/default.nix
        ├── host: hardware, impermanence, boot, networking, wireguard, users,
        │         ssh, maintenance
        └── modules: git, private-secrets
```

The graph is transcribed from the host entrypoints and flake special arguments;
it is **declared**, not a report of evaluated module output. The `wsl` output is
an abandoned legacy target and is excluded from this graph and all current
architecture work; see [`AGENTS.md`](../../AGENTS.md).

## Responsibilities and data flows

### Home media and administration

`server` declares media users and `/media` directories, Jellyfin,
qBittorrent, Sonarr, Radarr, Prowlarr, and local-only FlareSolverr. The source
also declares `reverse-ssh.service` for a restricted SSH listener and
`reverse-media-ssh.service` for forwarding the five media remote ports from
`vps1` to server-local ports (**declared**). The exact forwards and gateway
behavior are documented in [VPN and tunnels](vpn-and-tunnels.md).

### Public gateway and VPN cascade

`vps1` declares the public firewall surface, an AmneziaWG client-entry
interface and uplink toward `vps2`, fail-closed policy routing, and Nginx
virtual hosts whose loopback backends are the reverse-media-ssh listeners.
`vps2` declares the AWG peer and NAT from `awg-exit` to `ens3`. The direction
and dependency chain are **inference** across host declarations; ports and
routes are listed in [networking](networking.md) and [VPN and tunnels](vpn-and-tunnels.md).

`server` also imports a secret-backed full-tunnel AmneziaWG service. Its
endpoint and route details are in the secret configuration rather than tracked
source, so they remain **unknown** here. Source-present Xray modules are not
represented as a current path.

### Persistence and operations

Each supported host declares a different boot and persistence model. The
comparison and recovery-sensitive boundaries are in [storage and boot](storage-and-boot.md).
The repository declares no backup implementation or backup-success evidence;
see [backup and restore](../operations/backup-restore.md).

## Active, dormant, and excluded source

“Active” below means imported by a supported host entrypoint, not running at
runtime:

- The supported source path imports AmneziaWG on `server`, `vps1`, and `vps2`,
  and the media gateway only on `vps1` (**declared**).
- The server auto-update aggregate is source-present but commented out in
  [`hosts/server/default.nix`](../../hosts/server/default.nix); it is dormant by
  source import (**declared**).
- Xray modules remain source-present under
  [`modules/server/vpn/`](../../modules/server/vpn/) but are not imported by
  the supported server entrypoint; they are dormant/unsupported here
  (**declared**).
- Legacy 3x-ui data is mentioned by VPS persistence declarations and historical
  docs, but no current host entrypoint imports the 3x-ui module; it is not
  documented as an active service (**declared**).
- The `wsl` output is excluded legacy source and is not a supported target.

None of these labels proves a running unit. Use [runtime diagnostics](../operations/runtime-diagnostics.md)
for owner-approved, read-only evidence collection.
