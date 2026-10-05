# VPS2

`vps2` is the second node of the VPN cascade. It uses the static IPv4 address
`104.128.142.208/24` on `eth0`, with gateway `104.128.142.1` and DNS server
`8.8.8.8`.

The provider VM has a 5 GiB `/dev/vda` disk, 709 MiB RAM, legacy BIOS boot,
and virtio devices. Its disk is partitioned manually; this host intentionally
does not import disko.

The root filesystem is ephemeral. `/nix`, `/persist`, the 3x-ui state, Podman
storage, system identity, host keys, and bounded logs persist across reboots.

Port `2053/TCP` is only for the initial 3x-ui setup. After creating and testing
the VLESS REALITY inbound on `443/TCP`, remove `2053` from the firewall and add
`443`.

See `migration-runbook.md` before changing the VPS.
