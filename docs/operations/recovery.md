# Recovery runbook skeleton

## Scope and evidence

This is an owner-led recovery boundary, not a recovery procedure. The
supported storage models and recovery-sensitive declarations are in [storage
and boot](../architecture/storage-and-boot.md). Current mounts, disk identity,
boot entries, active generations, persistence contents, media availability,
and provider-console access are **unknown** without dated evidence.

No recovery, rollback, repair, formatting, remount, reboot, activation, or
remote command is provided here. Historical migration documents are not current
recovery instructions: [VPS1 migration](../../hosts/vps1/migration-runbook.md),
[VPS2 migration](../../hosts/vps2/migration-runbook.md), and [VPS2 ISO
bootstrap](../../hosts/vps2/iso-network-bootstrap.md).

## Stop conditions

Stop and obtain owner direction if any of the following is true:

- the affected host/output or current generation cannot be identified;
- a disk, filesystem, EFI/NVRAM, bootloader, mount, `/persist`, `/nix`, `/boot`,
  or `/media` condition is uncertain;
- the issue involves a connectivity-critical VPN, reverse tunnel, firewall,
  route, DNS, SSH, or public access;
- secret, private-key, provider, or backup credentials would be needed;
- a proposed action could delete, format, overwrite, remount, restart, reboot,
  activate, or change network/storage state;
- the only evidence is a source declaration, historical note, or unredacted
  log rather than owner-approved current evidence.

`/media` is user data and must not be deleted, moved, or reconfigured as an
assumed cleanup step. Impermanence and persistence declarations are not backups.

## Owner approval gate

Before recovery work, the owner must approve the exact host, failure scope,
access method, commands/actions, data-protection plan, maintenance window,
rollback/abort condition, and evidence capture. Remote access, privileged
access, activation/rollback, reboot, storage/boot changes, network changes,
secret access, and restore from backup each require explicit approval.

The operator must preserve the original evidence, redact credentials and
sensitive logs, and stop if the approved scope changes. If no approved backup
or provider snapshot can be identified, recoverability is **unknown** and no
restore should be assumed.

## Read-only first response

Use [runtime diagnostics](runtime-diagnostics.md) for local, read-only checks of
failed units, mounts, routes, interfaces, listeners, timers, and narrow journal
windows. Record host, timestamp, check, exit status, and redacted result. A
failed unit or missing mount is evidence of a discrepancy, not authorization to
restart or repair it.

After owner-led action, retain an outcome record and link it to the relevant
source declaration. Do not claim recovery success without dated runtime or
provider evidence.
