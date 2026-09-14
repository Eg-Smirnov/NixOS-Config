# vps1 NixOS migration runbook

This runbook is for migrating VPS1 (`103.71.20.103`) from Ubuntu to NixOS and
restoring 3x-ui `v3.2.6`. It assumes the provider snapshot and the two local
3x-ui backups already exist.

## Current backups

- Provider snapshot of VPS1.
- Manual 3x-ui archive: `C:\Users\Egor\3xui-backup.tar.gz`.
- Panel database backup: `C:\Users\Egor\Downloads\x-ui.db`.

Keep both 3x-ui backups outside Git.

## Local repository status

- NixOS host: `hosts/vps1`.
- Flake output: `nixosConfigurations.vps1`.
- Static interface: `ens3`.
- IPv4 address: `103.71.20.103/24`.
- Gateway: `103.71.20.1`.
- Public TCP ports observed on Ubuntu: `22`, `2096`, `7142`, `35474`, `52542`.
- 3x-ui state directory on NixOS: `/var/lib/3x-ui`.
- 3x-ui database volume on host: `/var/lib/3x-ui/db`.
- 3x-ui certificate volume on host: `/var/lib/3x-ui/cert`.

## Do before reinstall

- Confirm the provider snapshot is restorable.
- Confirm out-of-band console access in the provider panel.
- Keep the current Ubuntu port list nearby for comparison.
- Decide whether the 20-minute window is only preparation or includes outage.
- Do not start if a rollback delay would be a problem right now.

## Install and first boot

- Reinstall VPS1 to NixOS through the provider panel or installer.
- Boot once into the new system.
- Generate the real hardware configuration on the VPS.
- Replace `hosts/vps1/hardware-configuration.nix` with the generated file.
- Check that the generated root filesystem, boot loader, and disk naming match
  the provider VM.
- Evaluate or build `nixosConfigurations.vps1` before any activation.

## 3x-ui restore shape

The NixOS module runs the upstream container with host networking and these
persistent mounts:

- `/var/lib/3x-ui/db` mounted as `/etc/x-ui`.
- `/var/lib/3x-ui/cert` mounted as `/root/cert`.

Restore expectation:

- `x-ui.db` belongs under `/var/lib/3x-ui/db`.
- TLS certificates from the manual archive, if used by existing inbounds, belong
  under `/var/lib/3x-ui/cert`.
- Restore on the same 3x-ui version first, then upgrade only after confirming
  clients work.

## Post-restore checks

- 3x-ui panel opens on the expected panel port.
- Xray listens on the same public inbound ports as before migration.
- Loopback-only inbounds remain loopback-only if they are still expected.
- Existing clients connect through VPS1.
- VPS1 still behaves correctly as the VPN cascade entry.
- Firewall exposes only the intended public TCP ports.

## Rollback trigger

Use the provider snapshot if any of these happen and cannot be resolved quickly:

- no console or administrative access after boot;
- static network does not come up;
- 3x-ui database restore fails;
- public inbounds differ from the saved Ubuntu state;
- cascade entry traffic fails and there is no fast local fix.

After rollback, capture what failed before trying another migration window.
