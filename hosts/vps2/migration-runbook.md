# VPS2 NixOS migration runbook

This runbook replaces the broken Ubuntu installation on VPS2 with NixOS. There
is no data to restore. The provider console must remain available until NixOS
has booted twice with working networking and administrative access.

## Observed Ubuntu state

- Disk: `/dev/vda`, 5 GiB.
- Firmware: legacy BIOS.
- Memory: 709 MiB RAM; Ubuntu currently has 767 MiB swap.
- Ubuntu interface: `eth0`; the NixOS installer uses `ens3`, which is also the
  interface configured for the installed system.
- IPv4: `104.128.142.208/24`.
- Gateway: `104.128.142.1`.
- DNS: `8.8.8.8`.
- IPv6 has an address but no default route and is intentionally not configured
  during the initial NixOS migration.

## Safety gates

Before every remote command, disk write, installation, reboot, or activation,
state the exact command, target, and expected effect and obtain explicit
confirmation. Do not continue if the rescue environment reports a disk other
than the expected 5 GiB `/dev/vda`.

Keep the provider console open throughout the first boot. Do not remove rescue
access until key-only administrative access works in a second session.

## Manual disk layout

Do not use disko. From the NixOS rescue environment, create this GPT layout
manually after confirming `/dev/vda` is the intended destructive target:

1. A 1 MiB BIOS boot partition with the `bios_grub` flag.
2. A 1 GiB swap partition labelled `swap`.
3. A Btrfs partition using all remaining space, labelled `nixos`.

Create the Btrfs subvolumes `root`, `nix`, and `persist`. Mount `root` at
`/mnt`, then mount `nix` and `persist` at their matching paths with
`compress=zstd` and `noatime`. Enable the labelled swap before installation so
the 709 MiB VM has enough memory headroom.

## Installation

1. Copy or clone this repository into the rescue environment without placing
   credentials in it.
2. Recheck the mounted filesystems and active swap.
3. Evaluate and install `nixosConfigurations.vps2` with one build job and one
   core.
4. Reboot through the provider console.
5. Verify the static IPv4 route, DNS, key-only login as `server`, sudo, swap,
   filesystem mounts, and free disk space.
6. Reboot once more and verify that the root subvolume was recreated while the
   machine identity and host keys remained stable.

## 3x-ui bootstrap

The initial firewall permits `22/TCP` and `2053/TCP`. The upstream default
panel credentials are public knowledge, so do not leave the fresh panel
unattended. Use the provider console to set a unique username, strong password,
and long non-default web path before the brief public setup window.

Create one VLESS REALITY inbound on `443/TCP` for traffic arriving from VPS1.
After it works directly:

1. Replace `2053` with `443` in `networking.firewall.allowedTCPPorts`.
2. Build and activate the final VPS2 configuration after explicit confirmation.
3. Confirm that the panel is no longer reachable publicly.
4. Change VPS1 to use the new endpoint only in a separate, confirmed cutover.

## Acceptance checks

- Only `22/TCP` and, after bootstrap, `443/TCP` are reachable publicly.
- 3x-ui and its SQLite database survive two reboots.
- At least 1 GiB remains free after the 3x-ui image is present.
- Nix GC, journal limits, and Podman image pruning are enabled.
- A test client exits through the complete VPS1 to VPS2 cascade.
- The old reverse-tunnel service is absent from the home server after that
  host receives its separately confirmed activation.
