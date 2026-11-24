# Supported host matrix

This page maps flake outputs to their host entrypoints and source-declared
responsibilities. **Declared** and **inference** are source evidence labels;
active generations, runtime units, routes, reachability, mounts, and health are
**unknown**. Start with the [system overview](system-overview.md), then follow
host-specific detail to [networking](networking.md), [VPN and tunnels](vpn-and-tunnels.md),
[services](services.md), and [storage and boot](storage-and-boot.md).

| Output | Host entrypoint | Declared responsibility | Key source paths |
|---|---|---|---|
| `server` | [`hosts/server/default.nix`](../../hosts/server/default.nix) | Home host: local networking, secret-backed AmneziaWG, reverse SSH/media tunnels, media stack, power/sleep/thermal automation, and agent workspace (**declared**) | [`flake.nix`](../../flake.nix), [`hosts/server/networking.nix`](../../hosts/server/networking.nix), [`hosts/server/agent-workspace.nix`](../../hosts/server/agent-workspace.nix), [`modules/server/vpn/amneziawg.nix`](../../modules/server/vpn/amneziawg.nix), [`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix), [`modules/server/media.nix`](../../modules/server/media.nix) |
| `vps1` | [`hosts/vps1/default.nix`](../../hosts/vps1/default.nix) | Public VPN ingress, AWG uplink toward VPS2, fail-closed client routing, restricted reverse-tunnel endpoint, Nginx media gateway, and ACME (**declared/inference**) | [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix), [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix), [`hosts/vps1/ssh.nix`](../../hosts/vps1/ssh.nix), [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix), [`modules/vps/private-secrets.nix`](../../modules/vps/private-secrets.nix) |
| `vps2` | [`hosts/vps2/default.nix`](../../hosts/vps2/default.nix) | AWG egress and NAT to the public interface, static networking, persistence, boot, and maintenance (**declared**) | [`hosts/vps2/networking.nix`](../../hosts/vps2/networking.nix), [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix), [`hosts/vps2/impermanence.nix`](../../hosts/vps2/impermanence.nix), [`hosts/vps2/maintenance.nix`](../../hosts/vps2/maintenance.nix) |

## Host-local documentation

- [`hosts/vps1/README.md`](../../hosts/vps1/README.md) is host-local source
  context for the AWG entry node. Its client-profile procedure requires a
  separate owner-approved operational task; it is not a deployment procedure
  in this documentation set.
- [`hosts/vps2/README.md`](../../hosts/vps2/README.md) records host-local
  storage/network context and links to historical material.
- [`docs/agent-workspace.md`](../agent-workspace.md) covers the declared agent
  workspace and owner-stated historical observations.

## Excluded legacy output: `wsl`

The `wsl` output and [`hosts/wsl`](../../hosts/wsl) are an **abandoned legacy
target**, outside the supported architecture. Do not change, evaluate, build,
or maintain them without a separate owner request, as required by
[`AGENTS.md`](../../AGENTS.md). Their declaration in `flake.nix` is not runtime
or support evidence.

## Boundaries and unknowns

- The private `secrets` input and SOPS consumers are recorded only as
  dependency boundaries; no secret value or private input content is documented.
- [Security and secrets](security-and-secrets.md) lists field names only; it
  does not establish presence, values, permissions, or active use.
- The supported server entrypoint imports AmneziaWG and comments out the
  auto-update aggregate. Xray source modules are not a supported current VPN
  path; see [system overview](system-overview.md).
- Existing migration runbooks are historical and must not be used as current
  deployment or recovery instructions: [`vps1 migration`](../../hosts/vps1/migration-runbook.md),
  [`vps2 migration`](../../hosts/vps2/migration-runbook.md), and [`vps2 ISO bootstrap`](../../hosts/vps2/iso-network-bootstrap.md).
- Runtime interfaces, routes, firewall state, DNS/TLS, active generations,
  mounts, service health, backup state, and provider snapshots were not
  observed here and remain **unknown**.
