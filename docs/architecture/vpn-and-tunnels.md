# VPN and tunnel flows

The flows below are source-grounded. `declared` means a tracked configuration
sets the relationship; `inference` means the direction is reconstructed from
multiple declarations. Active interfaces, routes, tunnel health, and service
reachability remain **unknown**.

## AmneziaWG cascade

1. A client peer is accepted by `vps1` on UDP 30326 (**declared** in
   [`hosts/vps1/networking.nix`](../../hosts/vps1/networking.nix) and
   [`hosts/vps1/wireguard.nix`](../../hosts/vps1/wireguard.nix)).
2. `vps1` uses `awg-uplink` at `10.200.0.1/30` toward
   `104.128.142.208:30326`, with client subnet `10.201.0.0/24` routed through
   table 100 (**declared**).
3. `vps2` receives the uplink at `10.200.0.2/30` and NATs traffic from the AWG
   interface to `ens3` (**declared** in
   [`hosts/vps2/wireguard.nix`](../../hosts/vps2/wireguard.nix)).

The blackhole default in the `vps1` client routing table is a declared
fail-closed boundary. It does not prove that the watchdog or route is active.

## Server reverse SSH

The server uses a reverse-SSH service to connect to `103.71.20.103` on port 22
and expose a restricted remote listener for SSH (**declared/inference** from
[`hosts/server/infrastructure.nix`](../../hosts/server/infrastructure.nix) and
[`modules/server/reverse-ssh.nix`](../../modules/server/reverse-ssh.nix)). VPS1
restricts the `reverse-tunnel` account to port forwarding and permitted
listeners in [`hosts/vps1/ssh.nix`](../../hosts/vps1/ssh.nix). No key or
credential value is documented.

## Public media path

The source declares public Nginx virtual hosts on `vps1` and reverse-tunnel
remote ports `18096`, `18989`, `17878`, `19696`, and `18080`, mapping to local
server ports `8096`, `8989`, `7878`, `9696`, and `8080` (**declared** in
[`hosts/server/infrastructure.nix`](../../hosts/server/infrastructure.nix)).
The gateway proxies to loopback backends and can return 503 when a backend is
unavailable (**declared** in [`modules/vps/media-gateway.nix`](../../modules/vps/media-gateway.nix)).
DNS, TLS, tunnel state, backend health, and public reachability are **unknown**.

## Unsupported/dormant path

Xray source modules are not presented as a working VPN. The supported VPN path
in this documentation is AmneziaWG; see the [system overview](system-overview.md).
