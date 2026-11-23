# Declared networking

All values below come from repository source at baseline
`1dccc6193fcf6214b0ca7fd260c877c68077847b`. They describe intended
configuration (**declared**), not observed interface or reachability state.

## Host addresses and firewall surface

| Host | Interface/address or gateway | Declared allowed ports | Source |
|---|---|---|---|
| `vps1` | `ens3`: `103.71.20.103`; gateway `103.71.20.1` | TCP 22, 80, 443; UDP 30326 | [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix) |
| `vps2` | `ens3`: `104.128.142.208`; gateway `104.128.142.1` | TCP 22; UDP 30326 | [`hosts/vps2/networking.nix`](../../hosts/vps2/networking.nix) |
| `server` | hostname `home-server`; local addressing is delegated to NetworkManager source | not summarized here | [`hosts/server/networking.nix`](../../hosts/server/networking.nix) |

The firewall declarations are not proof that ports are reachable from any
network. DNS, TLS certificates, active firewall rules, and listening sockets
are **unknown** in this source-only task.

## Routing boundaries

`vps1` declares an AWG uplink `10.200.0.1/30` to `104.128.142.208:30326` and
routes client subnet `10.201.0.0/24` through routing table 100. Its watchdog
installs a blackhole default in that table, so the declared client path fails
closed rather than falling back to the public interface (**declared**, runtime
state unknown). See [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix).

`vps2` declares AWG address `10.200.0.2/30`, allows the peer `10.200.0.1/32`
and client subnet `10.201.0.0/24`, and performs NAT from the AWG interface to
`ens3` (**declared**). See [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix).

## Boundary conditions

No claim is made here about active routes, interface names at runtime, DNS/TLS,
firewall state, or end-to-end reachability. Xray source modules are not
described as an active VPN; AmneziaWG is the supported source-declared path.
