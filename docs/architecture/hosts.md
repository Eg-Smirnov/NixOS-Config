# Host matrix

Baseline: `cd51e17d266f83a78fda9d3f070a51623b605925` (2026-11-22 source
inventory). The table records source-level declarations and inferences only;
active runtime status and reachability are **unknown** unless separately
evidenced.

| Output | Host entrypoint | Declared responsibility | Key source paths |
|---|---|---|---|
| `server` | [`hosts/server/default.nix`](../../hosts/server/default.nix) | Home host: NetworkManager/Wi-Fi, AmneziaWG client, reverse SSH/media tunnels, media stack, power/sleep/thermal automation, and agent workspace (**declared**) | [`flake.nix`](../../flake.nix), [`hosts/server/networking.nix`](../../hosts/server/networking.nix), [`hosts/server/agent-workspace.nix`](../../hosts/server/agent-workspace.nix), [`modules/server/vpn/amneziawg.nix`](../../modules/server/vpn/amneziawg.nix), [`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix), [`modules/server/media.nix`](../../modules/server/media.nix) |
| `vps1` | [`hosts/vps1/default.nix`](../../hosts/vps1/default.nix) | Public VPN ingress, AmneziaWG uplink toward VPS2, fail-closed client routing, reverse-tunnel endpoint, Nginx media gateway, and ACME (**declared/inference**) | [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix), [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix), [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix), [`modules/vps/private-secrets.nix`](../../modules/vps/private-secrets.nix) |
| `vps2` | [`hosts/vps2/default.nix`](../../hosts/vps2/default.nix) | AmneziaWG egress and NAT to the public interface, static networking, persistence, and maintenance (**declared**) | [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix), [`hosts/vps2/networking.nix`](../../hosts/vps2/networking.nix), [`hosts/vps2/impermanence.nix`](../../hosts/vps2/impermanence.nix), [`hosts/vps2/maintenance.nix`](../../hosts/vps2/maintenance.nix) |

## Excluded legacy output: `wsl`

[`wsl`](../../flake.nix) and [`hosts/wsl`](../../hosts/wsl) are an **abandoned
legacy target**, outside the supported architecture. Do not change, evaluate,
build, or maintain them without a separate owner request, as required by the
repository [`AGENTS.md`](../../AGENTS.md). The output's declaration in
`flake.nix` is not runtime evidence and does not make this target supported.

## Boundaries and unknowns

- The private `secrets` input and SOPS consumers are recorded only as dependency
  boundaries; no secret value or private input content is documented.
- Host-specific secret field names are listed in the [security and secrets
  inventory](security-and-secrets.md); the templates contain names only and do
  not establish presence, value, permissions, or runtime use.
- The source contains Xray and auto-update aggregates, but the supported server
  entrypoint imports AmneziaWG and comments out auto-update; Xray is abandoned
  in favour of AmneziaWG per owner decision. No service is called active solely
  because a module exists.
- The source inventory did not inspect runtime interfaces, routes, firewall
  state, DNS/TLS, active generations, mounts, or service health. Those fields
  remain **unknown**.
- Existing host READMEs are useful source-linked context, not independent
  runtime authority: [`vps1 README`](../../hosts/vps1/README.md) and
  [`vps2 README`](../../hosts/vps2/README.md).
