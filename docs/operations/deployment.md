# Deployment runbook skeleton

## Scope

This page describes a review and handoff process for the supported flake outputs
`server`, `vps1`, and `vps2`. It is documentation only. It contains no
activation command, remote operation, firewall change, tunnel restart, mount
change, reboot, or secret access. The source map is in the [system overview](../architecture/system-overview.md).

A successful evaluation or build would establish only a source/build result;
it would not prove runtime health, reachability, backups, or safe recovery.

## Evidence and preflight

1. Record the target output, source revision, intended scope, owner, and
   rollback/recovery decision. The target must be one of the supported outputs
   in [hosts](../architecture/hosts.md).
2. Confirm the worktree contains only intended changes and review source links.
3. Run the repository's non-activating checks as appropriate. Current CI is
   manual-dispatch only and runs `nix flake check` plus the server toplevel
   build, as declared in [`.github/workflows/nixos.yml`](../../.github/workflows/nixos.yml).
   CI has no Markdown link checker or Mermaid renderer. The private flake input
   may make checks unavailable to an unprivileged checkout; record that result
   rather than bypassing access.
4. For an existing host, collect only owner-approved, read-only evidence using
   [runtime diagnostics](runtime-diagnostics.md). Record host, timestamp,
   command, exit status, and redacted output.

The source declares host-specific storage, networking, VPN, and service effects;
see [networking](../architecture/networking.md), [storage and boot](../architecture/storage-and-boot.md),
and [services](../architecture/services.md). None of those declarations proves
current state.

## Owner approval gate

Before any activation or deployment action, the owner/administrator must
explicitly approve the exact target, revision, intended effect, maintenance
window, access path, rollback authority, and evidence required afterward.
Activation, reboot, rollback, remote access, firewall/routing/VPN changes,
secret handling, and storage/boot changes are separate approval-sensitive
operations. This documentation task performs none of them.

The implementer must stop instead of proceeding when approval is missing, the
source revision is ambiguous, the target differs from the approved output, the
private input is unavailable, a secret would need to be displayed, or a check
shows a storage, boot, connectivity-critical tunnel, unexpected listener, or
credential exposure concern.

## Handoff and post-action evidence

The owner records the action and outcome outside this source-only document:
revision, target, timestamp, generation/result, service and connectivity
observations, and any rollback decision. Do not copy secrets or unredacted
logs. If runtime evidence is not collected, deployment status remains
**unknown**. See [troubleshooting](troubleshooting.md) for read-only follow-up
and [recovery](recovery.md) for stop conditions.

`wsl` is excluded and must not be deployed, evaluated, built, or maintained
without a separate owner request, per [`AGENTS.md`](../../AGENTS.md).
