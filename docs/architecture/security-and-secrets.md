# Security and secret-field inventory

This page records only field names from the owner-provided templates in
[`docs/secret-templates/`](../secret-templates/). The files are treated as
plain-text field-name evidence rather than parsed secret configuration. No secret
value, private key material, decrypted SOPS data, or private input content is
present here. For the architecture boundary use [system overview](system-overview.md);
for owner-gated handling and diagnostics use [deployment](../operations/deployment.md)
and [runtime diagnostics](../operations/runtime-diagnostics.md).

## Template fields by host

| Template | Field names | Source/evidence label |
|---|---|---|
| [`home-server.yaml`](../secret-templates/home-server.yaml) | `wifi_ssid`, `wifi_psk`, `jellyfin_api_sleep`, `reverse_tunnel_private_key`, `ssh_private_key`, `ssh_git_agent_key`, `vpn_config`, `amneziawg_config` | owner-provided field-name template; presence and use are **unknown** until mapped to source consumers |
| [`vps1.yaml`](../secret-templates/vps1.yaml) | `awg_entry_private_key`, `awg_uplink_private_key` | owner-provided field-name template; presence and use are **unknown** until mapped to source consumers |
| [`vps2.yaml`](../secret-templates/vps2.yaml) | `awg_private_key` | owner-provided field-name template; presence and use are **unknown** until mapped to source consumers |

## Source-level consumers and boundaries

The repository declares secret consumers without exposing their values:

- Server SOPS and networking modules reference Wi-Fi, tunnel, AmneziaWG, and
  Jellyfin-related secret paths; see [`hosts/server/sops.nix`](../../hosts/server/sops.nix),
  [`hosts/server/networking.nix`](../../hosts/server/networking.nix),
  [`modules/server/vpn/amneziawg.nix`](../../modules/server/vpn/amneziawg.nix),
  [`modules/server/night-sleep.nix`](../../modules/server/night-sleep.nix), and
  [`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix).
- VPS host modules consume private input-backed and AmneziaWG key material; see
  [`modules/vps/private-secrets.nix`](../../modules/vps/private-secrets.nix),
  [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix), and
  [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix).

The mapping between template field names and exact source secret keys is not
asserted here because source secret values/private inputs are out of scope. A
future bounded task may add a
non-secret mapping after reviewing open source declarations.

## Safety boundary

Template fields do not prove that a secret exists, is populated, readable, or
used by an active generation. Backup or recovery claims about secret material
are also **unknown**; no secret backup is documented here. Do not replace these
placeholders with values, commit real credentials, decrypt SOPS data, or treat
this inventory as runtime evidence. The repository [`AGENTS.md`](../../AGENTS.md)
remains authoritative for secret handling and owner approval gates.
