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

Peer public keys and tunnel parameters are declared in Nix. The private keys
are supplied through SOPS. Add client peers manually to `wireguard.nix` and
issue their profiles out of band. The fresh client profile uses endpoint
`103.71.20.103:30326`, server public key
`9FhghHiEk1Ew1yZFo+5jAChoiiZU0srXTL2PmZeLZSg=`, and `AllowedIPs =
0.0.0.0/0`. Assign client addresses from `10.201.0.2/32` upward. Match these
AmneziaWG interface options in each client profile:

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
