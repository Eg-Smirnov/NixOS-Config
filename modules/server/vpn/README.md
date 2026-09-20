# AmneziaWG 3.1 on the NixOS server

`amneziawg.nix` prepares a full-tunnel client using upstream AmneziaWG Go
3.1.20260828 and AmneziaWG tools 3.1.20260812. These versions are pinned in
the module because the repository's nixpkgs revision provides older releases.

The encrypted `secrets.yaml` needs a separate `amneziawg_config` key containing
the complete native AmneziaWG `.conf` profile. The service reads it at runtime
from `/run/secrets/awg0.conf`; no private key or profile content belongs in Nix
source or the Nix store. Keep the existing `vpn_config` key for the WSL Xray
configuration.

The profile must have `[Interface]` and `[Peer]` sections, an interface address,
an endpoint, and `AllowedIPs = 0.0.0.0/0` for the IPv4 full tunnel. Use the
AmneziaWG 3.1 format rather than an application connection link. The profile
must be named `awg0.conf` at runtime because `awg-quick` derives the interface
name from the filename. Do not include untrusted `PreUp`, `PostUp`, `PreDown`,
or `PostDown` hooks: `awg-quick` executes them as root.

After adding the encrypted key, enable the import in `hosts/server/default.nix`
and evaluate the server configuration before any activation. The new service
will change default internet routing and DNS behavior if the profile has a
`DNS` field. Existing LAN routes remain more specific than the VPN's default
route. The timer checks for the `awg0` interface and an IPv4 internet route
through it, then restarts the service if either is missing.

`awg-quick` uses the configured `amneziawg-go` binary when the AmneziaWG kernel
module is unavailable. If an AmneziaWG kernel module is present, `awg-quick`
may select it instead; verify the engine on the target system before relying
on userspace-specific behavior.
