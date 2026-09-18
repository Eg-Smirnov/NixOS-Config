# vps1 migration scaffold

`vps1` is the NixOS target for `103.71.20.103`, the entry node of the VPN
cascade. The host is registered in `flake.nix`, but
`hardware-configuration.nix` is still a placeholder and must be replaced with
the file generated on the VPS before the first real activation.

Before using the host, verify these host-specific items:

- `hardware-configuration.nix`, generated on the VPS during NixOS install;
- confirmation that the static network and firewall values in `networking.nix`
  match the provider;
- the public key for the restricted reverse-tunnel account, if that tunnel is
  moved from the second VPS;
- persistent storage policy for `/var/lib/3x-ui`.

## 3x-ui

`modules/vps/3x-ui.nix` defines a pinned `v3.8.5` container service. Its state
directories are `/var/lib/3x-ui/db` and `/var/lib/3x-ui/cert`.

The 3x-ui restore must use the saved database and any TLS certificates. Keep
the backup outside this repository and do not add its contents to Git.
