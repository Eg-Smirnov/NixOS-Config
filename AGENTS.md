# NixOS safety rules

## Default operating mode

- Start with read-only inspection and explain the intended change before editing.
- Preserve all pre-existing uncommitted changes. Never discard, overwrite, stage, commit, or amend unrelated work.
- Before a consequential operation, state the exact command, affected target, and expected impact; wait for explicit user confirmation.
- Do not expose decrypted secrets, private keys, passwords, tokens, or their contents in terminal output, patches, commits, or replies.

## Operations requiring explicit confirmation

- Before writing, editing, suggesting for direct execution, or running any command or configuration text that contains `sops`, `age`, or `ssh`, obtain explicit user confirmation. This includes ostensibly read-only inspection, key paths, configuration fragments, and remote-access commands.
- Activate, stage, test, or roll back a NixOS generation: any `nixos-rebuild switch`, `boot`, `test`, `rollback`, reboot, shutdown, or equivalent remote activation.
- Change boot, firmware, storage, or persistence: EFI/NVRAM, bootloader, partitions, filesystems, mounts, UUIDs, `/persist`, `/nix`, `/media`, swap, formatting, or deletion of data.
- Remove or garbage-collect Nix data: `nix-collect-garbage`, `nix store delete`, `nix-store --delete`, profile deletion, or any recursive deletion.
- Update dependency pins or secrets: `nix flake update`, edits to `flake.lock`, any SOPS encrypt/decrypt/edit action, or age-key handling.
- Alter live networking or remote access: firewall rules, DNS, routes, NetworkManager profiles, Xray/VPN, reverse SSH tunnels, SSH daemon settings, or starting/stopping/restarting their systemd services.
- Run a command on a remote host, transfer files to or from one, publish changes (`git push`), create a pull request, or otherwise make an external state change.

## NixOS-specific checks

- Treat `nix build`, `nix flake check`, and evaluation as non-activation checks. They may download dependencies and populate the Nix store; report that beforehand when it is relevant.
- For a proposed configuration change, prefer evaluation/checks first. Only propose activation after checks succeed and its system effects have been summarized.
- Treat the full-tunnel Xray routing and its watchdog as connectivity-critical: do not restart or modify them without confirmation.
- Treat media paths as user data. Do not delete, move, chmod recursively, or reconfigure download locations without confirmation.

## Secrets and review

- `secrets.yaml` is encrypted SOPS data. Never decrypt it merely for inspection.
- Do not add plaintext credentials, private keys, or real secret values to tracked files.
- When reviewing changes involving access, networking, storage, boot, or secrets, call out the operational risk explicitly.
