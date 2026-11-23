# Runtime diagnostics guide

This guide is a bounded, read-only diagnostic aid for the supported `server`,
`vps1`, and `vps2` outputs. It does not establish that a service, route, mount,
tunnel, or generation is currently healthy. `wsl` is an abandoned legacy
target and is explicitly excluded.

## Evidence and safety rules

- **declared** — present in tracked Nix source or architecture documentation;
  it is not runtime proof.
- **observed** — output captured from a named host, with timestamp and command.
- **owner-stated** — a fact supplied by the owner and retained as such.
- **unknown** — no current evidence is available.

Record host, timestamp, command, exit status, and a redacted output excerpt for
every observation. Never copy passwords, private keys, tokens, full secret
configuration, or unredacted journal lines into task artifacts. Read-only does
not mean risk-free: paths, usernames, peer endpoints, process arguments, and
logs can disclose sensitive information.

These procedures are documentation only. The Developer does not run them on
runtime hosts as part of this task. Remote execution, SSH, sudo/privileged
invocation, activation, restart, network or storage changes, secret access, and
cleanup require an explicit owner gate and are never automatic remediation.

## Preconditions and stop conditions

Before a check, identify the host and obtain owner authorization for any remote
or privileged access. Use the host's local shell where possible, preserve the
original output privately, and redact before recording evidence.

Stop and escalate to the owner if a check suggests a failing connectivity-
critical tunnel, missing `/persist`/`/nix`/`/media` mount, disk or filesystem
errors, boot/EFI uncertainty, exposed credentials, unexpected listeners, or a
need to restart, repair, delete, remount, reconfigure, or activate anything.
This guide contains no recovery or remediation commands.

## Host boundaries

| Host | Diagnostic focus | Boundary |
|---|---|---|
| `server` | local filesystems/resources, AmneziaWG and reverse-tunnel declarations, media and automation units | `/media` is user data; tunnel changes and service restarts are owner-gated |
| `vps1` | public interfaces/routes, AWG uplink and fail-closed table, Nginx/ACME and gateway units | do not alter firewall, routes, tunnel, certificates, or public access |
| `vps2` | static networking, AWG/NAT declarations, persistence and maintenance units | storage, persistence, NAT, and cleanup are owner-gated |

The source-level host matrix is in [`architecture/hosts.md`](../architecture/hosts.md),
networking and tunnel boundaries in [`architecture/networking.md`](../architecture/networking.md)
and [`architecture/vpn-and-tunnels.md`](../architecture/vpn-and-tunnels.md),
storage boundaries in [`architecture/storage-and-boot.md`](../architecture/storage-and-boot.md),
and declared units in [`architecture/services.md`](../architecture/services.md).

## Safe diagnostic checks

Each check below is read-only when run locally without privilege. Treat the
result as **observed** only with host/timestamp evidence; otherwise it remains
**unknown**.

### Boot, storage, and resources

| Check | Host/prerequisite | Expected / unknown outcome | Stop gate |
|---|---|---|---|
| `findmnt` | all supported hosts; local shell | expected mounts may be listed; absence or unexpected source is observed evidence of a discrepancy, not a repair instruction | stop on missing or wrong `/persist`, `/nix`, `/boot`, or `/media` |
| `lsblk` (no destructive flags) | all; local shell | block devices and mount relationships may be observed; device identity remains unknown unless recorded with timestamp | stop on I/O/filesystem errors; do not format or repair |
| `df -h` | all; local shell | capacity snapshot; thresholds are not remediation policy | stop before deletion or cleanup, especially under `/media` or `/persist` |
| `free -h`, `uptime` | all; local shell | memory/load/uptime snapshot; transient values are not architecture facts | stop if response requires restart or resource changes |

Do not inspect or alter EFI/NVRAM, active generations, Btrfs subvolumes,
rollback-root behavior, or persistence contents as part of this guide.

### Network, VPN, and tunnels

| Check | Host/prerequisite | Expected / unknown outcome | Stop gate |
|---|---|---|---|
| `ip -brief address` | all; local shell | interfaces and addresses observed at a timestamp; declared addresses alone remain **declared** | stop on interface/address mismatch; do not reconfigure |
| `ip route` | all; local shell | current routes observed; fail-closed routing is not inferred from source alone | stop on missing/unsafe route; do not add, delete, or flush routes |
| `wg show` or the host's AWG status equivalent | `server`, `vps1`, `vps2`; local shell and tool available | peer/handshake counters may be observed; redact endpoints as needed; private keys are never collected | stop on tunnel failure or exposure; never restart or rewrite tunnel config |
| `ss -lntup` | all; local shell; process metadata may be sensitive | listening sockets observed; compare with declared architecture only as a discrepancy report | stop on unexpected public listener; do not kill or firewall processes |

Do not use SSH or other remote commands as an implicit prerequisite. Public
reachability, DNS, TLS, end-to-end VPN health, and reverse-tunnel health remain
**unknown** unless separately evidenced and owner-approved.

### Services and timers

| Check | Host/prerequisite | Expected / unknown outcome | Stop gate |
|---|---|---|---|
| `systemctl --failed` | local shell; service manager available | failed-unit list observed; empty output does not prove all application health | stop before restart/reset of any unit |
| `systemctl status <unit>` | local shell; use a unit already named in `architecture/services.md` | active/inactive state and recent metadata observed; source enablement is not runtime proof | redact logs/paths; stop on need to restart or alter dependencies |
| `systemctl list-timers --all` | local shell | timer schedule and last/next run observed; it does not prove job success | stop before manually triggering or changing a timer |
| `journalctl --unit=<unit> --since=... --no-pager` | local shell; narrow time window; redact output | timestamped log evidence may explain a unit state; journal content can contain sensitive data | stop and redact; do not expose credentials or treat one transient line as diagnosis |

Candidate units include those documented in the services architecture for
media, gateway, watchdog, reverse tunnel, sleep/thermal automation, and VPS2
maintenance. A unit's declaration, enablement, or timer schedule never proves
that it is running, healthy, reachable, or has completed successfully.

## Owner gates and future work

An owner decision is required before remote access, sudo, activation, restart,
route/firewall/VPN changes, mount or filesystem changes, EFI/NVRAM inspection,
secret handling, log export, or deletion/cleanup. Backup/restore, repair,
rollback, remediation, and recovery procedures belong to separate reviewed
tasks; this guide is evidence collection only.

For a future runbook, preserve the evidence label and exact host/timestamp,
link the relevant architecture source, state what remains unknown, and obtain a
new owner-approved scope before proposing any corrective action.
