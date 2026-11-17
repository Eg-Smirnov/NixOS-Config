# VPS2

`vps2` is the second node of the VPN cascade. It uses the static IPv4 address
`104.128.142.208/24` on `ens3`, with gateway `104.128.142.1` and DNS server
`8.8.8.8`.

The provider VM has a 5 GiB `/dev/vda` disk, 709 MiB RAM, legacy BIOS boot,
and virtio devices. Its disk is partitioned manually; this host intentionally
does not import disko.

`/boot` is a separate 256 MiB ext4 filesystem so GRUB never needs to read the
new Btrfs `block-group-tree` format. The root filesystem is ephemeral. `/nix`,
`/persist`, the 3x-ui state, Podman storage, system identity, host keys, and
bounded logs persist across reboots.

VPS2 is the AWG egress node in the cascade. It accepts the VPS1 uplink on UDP
`30326` and performs NAT to `ens3`. Public TCP access is limited to SSH on
port `22`; the former 3x-ui endpoints and panel are disabled. The old
`/var/lib/3x-ui` data remains persisted for rollback.

See `migration-runbook.md` before changing the VPS.
