# NixOS configuration documentation

## Scope and evidence

This documentation describes the repository's declarative source. It does not
prove that a generation is built, activated, reachable, backed up, or healthy.
Use these evidence labels consistently:

- **declared** — present in tracked Nix or Markdown source;
- **inference** — derived from multiple declarations;
- **owner-stated** — supplied by the owner and not independently checked here;
- **observed** — supported by dated runtime evidence;
- **unknown** — not established by the available evidence.

Source paths are repository-relative. Secret values, private keys, private flake
input contents, and credentials are intentionally excluded.

## Start here

| Need | Page | What it provides |
|---|---|---|
| System map | [System overview](architecture/system-overview.md) | Supported outputs, entrypoints/imports, responsibilities, and source-level data flows |
| Host map | [Host matrix](architecture/hosts.md) | Host-local entrypoints, responsibilities, source links, and boundaries |
| Operations | [Operations index](operations/deployment.md) | Deployment, recovery, backup/restore, troubleshooting, and diagnostics boundaries |
| Evidence collection | [Runtime diagnostics](operations/runtime-diagnostics.md) | Read-only checks; no remediation or activation |

## Architecture

- [System overview](architecture/system-overview.md) — the source-based architecture and import graph.
- [Hosts](architecture/hosts.md) — supported `server`, `vps1`, and `vps2` outputs.
- [Networking](architecture/networking.md) — declared addresses, firewall surface, and routing boundaries.
- [VPN and tunnels](architecture/vpn-and-tunnels.md) — AmneziaWG, reverse SSH, and media forwarding.
- [Services](architecture/services.md) — declared units, ports, timers, dependencies, and dormant source.
- [Storage and boot](architecture/storage-and-boot.md) — filesystems, impermanence, boot, and recovery-sensitive boundaries.
- [Security and secrets](architecture/security-and-secrets.md) — field-name inventory and secret-consumer boundaries only.

The architecture pages are intentionally cross-linked rather than duplicated.
Networking detail belongs in [networking](architecture/networking.md) and
[tunnel detail](architecture/vpn-and-tunnels.md); service detail belongs in
[services](architecture/services.md).

## Diagrams

The diagrams are source-labelled summaries, not runtime topology proofs:

- [Network topology](diagrams/topology.mmd)
- [Service dependencies](diagrams/service-dependencies.mmd)
- [Trust boundaries](diagrams/trust-boundaries.mmd)

There is no Mermaid renderer or link checker in CI. Review diagrams alongside
the linked source pages and treat every runtime state as **unknown** unless a
dated observation is attached.

## Current operations

These runbooks are deliberately skeletons. They identify evidence and approval
gates without providing activation, network-change, storage-change, repair, or
secret-handling procedures:

- [Deployment](operations/deployment.md) — review/build/owner activation gate.
- [Recovery](operations/recovery.md) — stop conditions and owner-led recovery scope.
- [Backup and restore](operations/backup-restore.md) — backup inventory gap and restore gate.
- [Troubleshooting](operations/troubleshooting.md) — symptom-to-read-only-evidence map.
- [Runtime diagnostics](operations/runtime-diagnostics.md) — bounded local diagnostics.

## Host-local and historical material

Host-local context is kept beside the host source:

- [`hosts/vps1/README.md`](../hosts/vps1/README.md)
- [`hosts/vps2/README.md`](../hosts/vps2/README.md)
- [Agent workspace](agent-workspace.md) — source and owner-stated workspace notes.

The following are historical records, not current procedures: [`vps1 migration
runbook`](../hosts/vps1/migration-runbook.md), [`vps2 migration
runbook`](../hosts/vps2/migration-runbook.md), and [`vps2 ISO bootstrap`](../hosts/vps2/iso-network-bootstrap.md).
They contain superseded installation or 3x-ui steps and must not be used as
current deployment instructions. The stage report is historical evidence:
[stage 1 report](agent-stage1-report.md).

## Supported outputs and explicit exclusions

The supported source outputs are `server`, `vps1`, and `vps2`, registered in
[`flake.nix`](../flake.nix). In source terms, `server` is the home host,
`vps1` is public ingress/media gateway, and `vps2` is AWG egress/NAT. This is
**declared/inference** only; active generations, service health, routes,
reachability, DNS/TLS, mounts, and backup state are **unknown**.

`wsl` and `hosts/wsl` are an abandoned legacy target. They are explicitly
excluded from this architecture and must not be inspected, evaluated, built,
changed, or maintained without a separate owner request, per
[`AGENTS.md`](../AGENTS.md). Their presence in the flake is not evidence of
support.

No current documentation claims that backups exist, that any tunnel is
connected, that a public endpoint is reachable, or that recovery is safe. Those
claims require owner-approved, dated runtime or provider evidence.
