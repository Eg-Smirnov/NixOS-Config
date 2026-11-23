# Network architecture overview

This page connects the supported [host matrix](hosts.md) to the source-declared
network zones and trust boundaries. It is a configuration map, not runtime
evidence: interfaces, routes, firewall state, DNS/TLS, tunnel health, and
reachability remain **unknown** unless separately observed.

## Zones and flows

- **Home server (`server` / `home-server`)** — source declares the local
  AmneziaWG client, reverse-SSH client, and media services (**declared**).
- **Public ingress (`vps1`)** — source declares public interface address
  `103.71.20.103`, TCP ports 22/80/443, and UDP 30326 (**declared**).
- **VPN egress (`vps2`)** — source declares the `10.200.0.2/30` AWG uplink,
  NAT to public interface `ens3`, and UDP 30326 (**declared**).
- **Public media clients** — clients reach Nginx virtual hosts on `vps1`; the
  source-to-backend path through reverse tunnels is an **inference** from the
  infrastructure and gateway declarations.

The supported VPN path is AmneziaWG: client ingress at `vps1`, an AWG uplink
to `vps2`, and NAT egress. Xray modules are not a supported/current VPN path.
The `wsl` output is an abandoned legacy target and is excluded from this
topology; see the [repository boundary](../../AGENTS.md).

## Evidence and sources

Addresses, ports, routes, and host roles are **declared** in
[`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix),
[`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix),
[`hosts/vps2/networking.nix`](../../hosts/vps2/networking.nix),
[`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix), and
[`hosts/server/infrastructure.nix`](../../hosts/server/infrastructure.nix).
Reverse-SSH restrictions are declared in
[`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix) and
[`hosts/vps1/ssh.nix`](../../hosts/vps1/ssh.nix). No source declaration proves
that any flow is currently active.
