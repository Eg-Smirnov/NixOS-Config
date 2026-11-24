# Backup and restore runbook skeleton

## What the repository establishes

The repository declares impermanence and persistence selections for `server`,
`vps1`, and `vps2`; see [storage and boot](../architecture/storage-and-boot.md).
It does **not** declare a backup job, backup destination, retention schedule,
provider snapshot inventory, restore test, or successful backup set. Therefore
backup existence, freshness, completeness, confidentiality, and recoverability
are **unknown**.

Persisted directories, Nix generations, historical runbook statements, and a
running host must not be treated as backups. `/media` is user data. Secret
material and private keys are separately restricted; see [security and
secrets](../architecture/security-and-secrets.md).

## Owner inventory gate

Before a restore is considered, the owner must identify and approve:

- the exact host, data set, source backup, timestamp, integrity evidence, and
  destination;
- whether the backup contains user media, `/persist`, databases, certificates,
  SSH keys, or secret material;
- the approved access method and maintenance window;
- the data-loss boundary, rollback/abort condition, and post-restore checks;
- who may handle credentials or provider snapshots.

No backup source, credential, private key, SOPS value, or provider console is
inspected by this documentation task. Do not paste backup listings or secret
contents into Git or issue records.

## Stop conditions

Stop if the backup cannot be authenticated to the owner-approved source, its
age or contents are unknown, integrity is not established, the target mount or
disk is uncertain, the operation could overwrite `/media`, `/persist`, `/nix`,
`/boot`, or a database, or secret handling would be required without an explicit
approval. Do not invent a backup or proceed from a historical 3x-ui archive
mentioned in migration documents.

Restore, copy, deletion, filesystem, mount, boot, activation, reboot, network,
remote-access, and secret operations are not described here because each is an
explicit owner gate. A restore plan must be separately reviewed before any
change is made.

## Read-only evidence and acceptance

Before and after an owner-approved restore, use the bounded checks in [runtime
diagnostics](runtime-diagnostics.md) where applicable. Capture host,
timestamp, check, exit status, and redacted output. Required acceptance evidence
is owner-defined and may include expected mounts, service state, data
availability, credentials/access, and network reachability; source declarations
alone cannot establish it.

Until an owner records a verified inventory and restore result, this repository
makes no backup or restore-success claim.
