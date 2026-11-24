# Declared networking

This page records source declarations for the supported `server`, `vps1`, and
`vps2` outputs. Values are **declared**, not observed: interfaces, routes,
firewall state, DNS/TLS, listening sockets, and reachability remain **unknown**
unless dated runtime evidence is collected. See [VPN and tunnels](vpn-and-tunnels.md)
for forwarding relationships and [runtime diagnostics](../operations/runtime-diagnostics.md)
for read-only evidence collection.

## Host addresses and firewall surface

| Host | Interface/address or gateway | Declared allowed ports | Source |
|---|---|---|---|
| `vps1` | `ens3`: `103.71.20.103/24`; gateway `103.71.20.1`; nameservers `1.1.1.1`, `8.8.8.8` | TCP `22`, `80`, `443`; UDP `30326` | [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix) |
| `vps2` | `ens3`: `104.128.142.208/24`; gateway `104.128.142.1`; nameserver `8.8.8.8` | TCP `22`; UDP `30326` | [`hosts/vps2/networking.nix`](../../hosts/vps2/networking.nix) |
| `server` | Hostname `home-server`; addressing delegated to NetworkManager/source-backed secret configuration | No host-level port summary is asserted here | [`hosts/server/networking.nix`](../../hosts/server/networking.nix) |

The firewall declarations do not prove that a port is reachable or that a
socket is listening. Do not infer DNS, certificate, provider-firewall, or
end-to-end state from this table.

## AmneziaWG routing boundaries

`vps1` declares two AWG interfaces in [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix):

- `awg-entry` uses the server address and listen port read from
  [`hosts/vps1/awg-clients.json`](../../hosts/vps1/awg-clients.json); the
  current source value is UDP `30326` and client subnet `10.201.0.0/24`.
- `awg-uplink` uses `10.200.0.1/30`, peers with `104.128.142.208:30326`, and
  disables automatic allowed-IP routes. Its setup script installs a default
  route in table `100`.

The `awg-client-routing-policy` unit installs a blackhole default in table 100
and a rule for `10.201.0.0/24`. This is a **declared fail-closed boundary**;
it does not prove that the unit, route, or interface is currently active.

`vps2` declares `awg-exit` at `10.200.0.2/30`, permits the peer `10.200.0.1/32`
and client subnet `10.201.0.0/24`, enables IPv4 forwarding, and NATs
`awg-exit` through `ens3` in [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix).

The server imports a secret-backed full-tunnel AWG service in
[`modules/server/vpn/amneziawg.nix`](../../modules/server/vpn/amneziawg.nix).
The secret configuration supplies endpoint and route details not present in
tracked source, so those details are **unknown** here.

## Boundary conditions

- Xray source modules are not described as an active VPN path. The supported
  source-declared path is AmneziaWG; see [system overview](system-overview.md).
- Reverse SSH and media forwarding are documented separately in [VPN and
  tunnels](vpn-and-tunnels.md); this page does not duplicate their port map.
- No claim is made about active routes, interface names at runtime, provider
  firewall state, DNS/TLS, handshakes, or public reachability.
- Network changes, tunnel restarts, firewall edits, and remote access require
  an explicit owner approval gate. No such operation is performed by this
  documentation task.
