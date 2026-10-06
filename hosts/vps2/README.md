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

The public VLESS REALITY endpoint permits `443/TCP` and `443/UDP`; UDP supports
transports that use HTTP/3/QUIC. The configured 3x-ui panel uses `3452/TCP`;
its initial `2053/TCP` bootstrap port is closed.

See `migration-runbook.md` before changing the VPS.
