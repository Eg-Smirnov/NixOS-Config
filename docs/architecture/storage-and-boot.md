# Storage, boot, and persistence architecture

This document compares the source-declared storage models of the supported
`server`, `vps1`, and `vps2` outputs. **Declared** means present in tracked Nix
source; **inference** means derived from those declarations; **owner-stated** and
**observed** require separate evidence; **unknown** means this source-only task
cannot establish the runtime fact. No statement here proves current mounts,
active generations, disk identity, EFI/NVRAM state, or successful reboot or
rollback.

## Host comparison

| Host/output | Filesystem and persistence model | Boot/initrd model | Recovery-sensitive boundary |
|---|---|---|---|
| `server` | Separate source-declared `/`, `/persist`, `/nix`, `/boot`, `/media`, and swap filesystems; impermanence persists selected `/var/lib`, NetworkManager connections, and server user state (**declared**) | systemd-boot, EFI variable access, configuration limit 10 (**declared**) | Device UUIDs, EFI state, mounts, generations, and media availability are **unknown** |
| `vps1` | disko declares GPT/ESP/swap on `/dev/vda`, LVM+Btrfs, and subvolumes mounted at `/`, `/nix`, `/persist`; selected identity/state persists (**declared**) | GRUB; `/persist` is needed for boot; initrd `rollback-root` recreates the root subvolume (**declared**) | Disk identity, disko layout, Btrfs state, rollback behavior, and boot success are **unknown** |
| `vps2` | Manual hardware source declares Btrfs subvolumes for `/`, `/nix`, `/persist`, separate ext4 `/boot`, and swap by label; selected identity/state persists (**declared**) | GRUB on `/dev/vda` with configuration limit 2; initrd recreates the ephemeral root subvolume (**declared**) | Labels, root recreation, boot disk, preserved state, and reboot success are **unknown** |

The `wsl` output is an abandoned legacy target outside the supported storage
matrix. It must not be changed, evaluated, or maintained without a separate
owner request; see [`AGENTS.md`](../../AGENTS.md).

## `server`: separate filesystems and media data

[`hosts/server/hardware-configuration.nix`](../../hosts/server/hardware-configuration.nix)
declares ext4 filesystems for `/`, `/persist`, `/nix`, and `/media`, a VFAT
`/boot`, and swap, each identified by a UUID (**declared**). The source does not
prove that these devices are present or mounted now (**unknown**).

[`hosts/server/impermanence.nix`](../../hosts/server/impermanence.nix) persists
`/var/lib`, NetworkManager connections, selected server keyring/history files,
and the server age-key path under `/persist` (**declared**). This is a source
selection, not evidence of current contents or accessibility.

[`modules/server/media.nix`](../../modules/server/media.nix) creates
`/media/downloads/{incomplete,complete}`, `/media/series`, and `/media/movies`
for the `media` group. These are user data and must not be treated as a
disposable cache or as safe deletion targets.

[`hosts/server/boot.nix`](../../hosts/server/boot.nix) declares systemd-boot,
EFI variable access, and a ten-generation configuration limit (**declared**).
Current EFI entries, generations, and boot behavior remain **unknown**.

## `vps1`: disko and rollback-root

[`hosts/vps1/disko.nix`](../../hosts/vps1/disko.nix) declares a `/dev/vda` GPT
layout with a BIOS boot partition, 512 MiB VFAT ESP at `/boot`, 2 GiB swap, and
an LVM physical volume containing a Btrfs logical volume. Btrfs subvolumes are
mounted at `/`, `/nix`, and `/persist` (**declared**). This is distinct from the
manual layout on `vps2`; no installation or formatting procedure follows from
this description.

[`hosts/vps1/impermanence.nix`](../../hosts/vps1/impermanence.nix) imports
`rollback-root.nix`, marks `/persist` needed for boot, and persists containers,
Nix state, logs, legacy 3x-ui state, machine identity, and SSH host keys
(**declared**). [`hosts/vps1/boot.nix`](../../hosts/vps1/boot.nix) declares GRUB.
The initrd rollback service's root-subvolume behavior is recovery-sensitive and
must not be treated as a recovery instruction; actual outcomes are **unknown**.

## `vps2`: manual layout and root recreation

[`hosts/vps2/hardware-configuration.nix`](../../hosts/vps2/hardware-configuration.nix)
declares a manual label-based model: Btrfs subvolumes `root`, `nix`, and
`persist`, a separate ext4 `/boot`, and swap. This is not the disko/LVM model of
`vps1` (**declared**).

[`hosts/vps2/impermanence.nix`](../../hosts/vps2/impermanence.nix) persists
containers, Nix state, logs, legacy 3x-ui state, machine identity, and SSH host
keys. Its initrd service recreates the `root` Btrfs subvolume while preserving
the separately declared `nix` and `persist` subvolumes (**declared**, runtime
behavior **unknown**). [`hosts/vps2/boot.nix`](../../hosts/vps2/boot.nix)
declares GRUB on `/dev/vda` with configuration limit 2.

## Data and owner gates

- `/media` and its subdirectories are user data; no deletion, movement, or
  reconfiguration is advised here.
- `/persist`, `/nix`, partitions, filesystems, bootloaders, EFI/NVRAM, mounts,
  generations, and rollback behavior are recovery-sensitive operational domains
  requiring an owner gate.
- This document contains no recovery/rollback commands, activation instructions,
  secret values, private input contents, or runtime inspection results.
- Evidence needed for a future recovery task includes owner-approved runtime
  facts about mounts, disk identity, active generation, boot state, persistence
  contents, and media availability. Until then these remain **unknown**.
