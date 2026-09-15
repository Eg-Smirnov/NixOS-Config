# vps1 NixOS migration runbook

This runbook is for migrating VPS1 (`103.71.20.103`) from Ubuntu to NixOS and
restoring 3x-ui `v3.2.6`. It assumes the provider snapshot and the two local
3x-ui backups already exist.

## Current backups

- Provider snapshot of VPS1.
- Manual 3x-ui archive: `C:\Users\Egor\3xui-backup.tar.gz`.
- Panel database backup: `C:\Users\Egor\Downloads\x-ui.db`.

Keep both 3x-ui backups outside Git.

## Migration status

The side-by-side migration has reached a working checkpoint:

- NixOS is installed on `/dev/vda2` and boots successfully.
- GRUB is installed on `/dev/vda` and retains an Ubuntu boot entry for rollback.
- Swap is active on `/dev/vda3`.
- Administrative access to the NixOS host is working.
- The 3x-ui `v3.2.6` container is running and the restored web panel is working
  over HTTPS on port `7142`.
- The subscription endpoint is working over HTTPS on port `2096`.
- The restored Xray public inbounds are listening on ports `35474` and `52542`.
- VPN connectivity has been confirmed on every device that worked before the
  migration.
- VPS1 is therefore functionally back at the pre-migration service level.

Do not remove the Ubuntu partition or provider snapshot until this checkpoint
has remained stable long enough to justify the final disk migration.

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

## Install and first boot (completed)

- Reinstall VPS1 to NixOS through the provider panel or installer.
- Boot once into the new system.
- Generate the real hardware configuration on the VPS.
- Replace `hosts/vps1/hardware-configuration.nix` with the generated file.
- Check that the generated root filesystem, boot loader, and disk naming match
  the provider VM.
- Evaluate or build `nixosConfigurations.vps1` before any activation.

## Correct 3x-ui restore procedure

The NixOS module runs the upstream container with host networking and these
persistent mounts:

- `/var/lib/3x-ui/db` mounted as `/etc/x-ui`.
- `/var/lib/3x-ui/cert` mounted as `/root/cert`.

Restore locations:

- The standalone panel backup `x-ui.db` belongs at
  `/var/lib/3x-ui/db/x-ui.db`.
- Certificate contents from `root/3xui-backup/cert/` in the manual archive
  belong under `/var/lib/3x-ui/cert/`. For the current backup this produces
  `/var/lib/3x-ui/cert/ip/fullchain.pem` and
  `/var/lib/3x-ui/cert/ip/privkey.pem`.
- Restore on the same 3x-ui version first, then upgrade only after confirming
  clients work.

The container must be stopped before replacing the database. Before installing
the backup, move aside or delete all three files from the current database
directory:

- `x-ui.db`
- `x-ui.db-wal`
- `x-ui.db-shm`

The `-wal` and `-shm` files are SQLite runtime sidecars. They must never be left
beside an `x-ui.db` copied from a different database instance. Doing so can make
SQLite replay unrelated data and cause 3x-ui to start with default or otherwise
incorrect settings. Prefer moving the files into a dated recovery directory
until the restore has been verified.

Safe restore order:

1. Stop `podman-3x-ui.service`.
2. Create a dated recovery directory outside the active database directory, or
   as a subdirectory that 3x-ui will not treat as its database.
3. Move the active `x-ui.db`, `x-ui.db-wal`, and `x-ui.db-shm` into it.
4. Copy the standalone backup to `/var/lib/3x-ui/db/x-ui.db` with owner
   `root:root` and mode `0644`.
5. Copy the certificate tree into `/var/lib/3x-ui/cert/`, preserving its
   directory structure and restrictive private-key permissions.
6. Confirm that no old `x-ui.db-wal` or `x-ui.db-shm` remains next to the newly
   restored database.
7. Start `podman-3x-ui.service`.
8. Verify the web panel, subscription endpoint, every public inbound, and a real
   client connection before deleting any recovery copy.

Do not restore only `x-ui.db` on top of files produced by a newly initialized
container. The first attempted restore failed for exactly this reason; the
standalone database worked after the unrelated WAL and SHM files were removed.

## Future impermanence

The current NixOS root filesystem is persistent, so `/var/lib/3x-ui` already
survives reboot. When VPS1 is moved to the final disko/impermanence layout,
persist at least these directories:

- `/var/lib/3x-ui` for the database, certificates, and panel state.
- `/var/lib/containers` for the Podman image and runtime storage.

Keep this host-specific under `hosts/vps1`; no `modules/common` change is needed.

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
