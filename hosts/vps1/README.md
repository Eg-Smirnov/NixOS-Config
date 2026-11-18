# VPS1

`vps1` is the NixOS target for `103.71.20.103`, the entry node of the VPN
cascade. Its NixOS configuration is registered in `flake.nix`; the home-server
reverse SSH tunnel and media gateway remain on this VPS.

## VPN

VPS1 accepts fresh AmneziaWG peers on UDP `30326`. Its `awg-uplink` interface
carries only client-subnet traffic to VPS2; policy routing keeps VPS1's own
management and media traffic on the public interface. A persistent blackhole
route prevents client traffic from falling back to the public interface if the
uplink interface disappears.

The public server settings, AmneziaWG parameters, and client public peers are
in `awg-clients.json`. NixOS reads the peer list from this file. Client private
keys stay in individual client profiles and are never stored in Git or SOPS.

Create a client profile from Ubuntu WSL at the repository root:

```sh
nix shell nixpkgs#python3 nixpkgs#amneziawg-tools \
  -c python3 scripts/new-awg-client.py --name tablet
```

Use a unique name for each device. The utility assigns the next free address,
generates a key pair with `awg`, writes a `.conf` file under
`~/.local/share/nixos-config/awg-client-profiles/` with mode `0600`, and adds
only the peer name, public key, and address to `awg-clients.json`. The private
profile stays in Ubuntu WSL's home directory, outside the repository.

Review and commit the JSON change manually, then build and activate the VPS1
configuration manually. The utility does not run Git commands, contact a
server, or activate a generation. Import the generated profile into the
AmneziaWG app and transfer it to the device securely.

Profiles use endpoint `103.71.20.103:30326`, server public key
`9FhghHiEk1Ew1yZFo+5jAChoiiZU0srXTL2PmZeLZSg=`, and full-tunnel IPv4 and IPv6
routes. VPS1 does not route IPv6, so the IPv6 route intentionally fails closed.
The matching AmneziaWG interface options are:

```ini
Jc = 4
Jmin = 40
Jmax = 70
S1 = 15
S2 = 25
H1 = 173829456
H2 = 285374619
H3 = 396485721
H4 = 508596832
```

Keep generated client profiles out of Git and distribute them privately.
Disable or block IPv6 on each client so it cannot bypass the IPv4 tunnel.

3x-ui has been removed from the active configuration. Its persisted data is
left on disk for rollback and is not mounted by any active service.
