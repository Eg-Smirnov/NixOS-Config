# Troubleshooting runbook skeleton

## Safety and evidence

This page maps symptoms to read-only evidence. It does not prescribe restart,
repair, activation, route/firewall changes, secret access, cleanup, storage
changes, or remote operations. A declaration in [services](../architecture/services.md),
[networking](../architecture/networking.md), or [VPN and tunnels](../architecture/vpn-and-tunnels.md)
is not proof of runtime state.

For every observation, record host, timestamp, check, exit status, and a
redacted excerpt. Treat the result as **observed** only with that context;
otherwise the condition remains **unknown**. Use [runtime diagnostics](runtime-diagnostics.md)
for the available read-only checks.

## Symptom map

| Symptom | Read-only evidence to collect | Source context | Stop condition |
|---|---|---|---|
| Host unavailable or SSH path fails | Owner-approved local console evidence; interface, route, failed-unit, and listener checks | [hosts](../architecture/hosts.md), [networking](../architecture/networking.md) | Do not change routes, firewall, SSH, tunnels, or provider settings |
| AWG client or cascade issue | Interface/address, route, and AWG status evidence on the affected host; redact endpoints as needed | [networking](../architecture/networking.md), [VPN and tunnels](../architecture/vpn-and-tunnels.md) | Stop on tunnel failure or unsafe fallback; never restart or rewrite VPN config from this guide |
| Public media endpoint fails | Nginx unit/timer state, listener evidence, narrow redacted journal evidence, and owner-approved backend evidence | [services](../architecture/services.md), [VPN and tunnels](../architecture/vpn-and-tunnels.md) | Do not reload Nginx, open allowlists, change DNS/TLS, or alter forwards |
| Media service unavailable | Failed-unit/status evidence and `/media` mount evidence on `server` | [services](../architecture/services.md), [storage and boot](../architecture/storage-and-boot.md) | Stop if `/media` is missing or any proposed action touches user data |
| Server sleeps or does not wake as expected | Timer listing and narrow unit evidence; do not infer RTC behavior from source | [services](../architecture/services.md) | Do not disable timers, force suspend/wake, or restart services |
| Disk, mount, or boot concern | Read-only mount, block-device, capacity, and resource evidence | [storage and boot](../architecture/storage-and-boot.md), [recovery](recovery.md) | Stop before repair, remount, rollback, reboot, EFI/NVRAM inspection, or deletion |
| Suspected credential or secret exposure | Preserve minimal evidence and escalate to owner; do not copy logs/configuration | [security and secrets](../architecture/security-and-secrets.md) | Stop immediately; no decryption, export, rotation, or publication |

## Owner gate and escalation

Obtain explicit owner approval before remote or privileged access, log export,
service restart, activation/rollback, reboot, route/firewall/VPN changes,
certificate/DNS changes, storage/boot changes, cleanup, backup/restore, or
secret handling. Stop when a symptom crosses those boundaries, when source and
runtime evidence disagree, or when the target host cannot be identified.

No current health, reachability, backup, or recovery claim can be made from
this page. The owner must supply dated runtime/provider evidence for those
claims. `wsl` is an abandoned legacy target and is excluded from troubleshooting
unless separately requested by the owner.
