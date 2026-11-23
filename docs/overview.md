# NixOS configuration overview

## Scope and evidence

This page is a navigation layer for the declarative configuration in this
repository. It describes what Git/Nix source declares; it does not prove that a
generation is built, activated, reachable, or healthy.

Evidence labels used throughout the documentation are:

- **declared** — directly present in a tracked Nix or Markdown source file;
- **inference** — a conclusion from declared imports or connections, not runtime
  evidence;
- **owner-stated** — supplied by the owner and not independently checked here;
- **observed** — supported by dated runtime evidence (none is collected by this
  task);
- **unknown** — not established by the available evidence.

Source paths are repository-relative and link to the files that support each
claim. Private inputs and secret values are intentionally not reproduced.

## Supported host outputs

The supported source topology is the `server`, `vps1`, and `vps2` outputs. The
entrypoints, declared responsibilities, and source cross-links are maintained
in the [host matrix](architecture/hosts.md).

At source level, `server` is the home host with AmneziaWG, reverse tunnels,
media services, power/sleep automation, and the agent workspace; `vps1` is the
public VPN ingress and media gateway; and `vps2` is the VPN egress/NAT host.
These are **declared** or **inferred** from [`flake.nix`](../flake.nix), host
entrypoints, and imported modules. Active generations, service health, network
reachability, DNS/TLS state, and current routes are **unknown** without separate
runtime evidence.

## Abandoned legacy target: `wsl`

The `wsl` flake output and `hosts/wsl` tree are an **abandoned legacy target**.
They are outside the supported architecture and must not be changed, evaluated,
built, or maintained without a separate owner request. This repository-level
boundary is defined in [`AGENTS.md`](../AGENTS.md); its presence in
[`flake.nix`](../flake.nix) is not evidence that it is supported or active.

## Documentation boundaries

The architecture pages deliberately separate source declarations from runtime
facts. Networking, VPN/tunnels, storage/boot, services, security/secrets, and
operational runbooks require their own bounded tasks and evidence. Historical
migration documents are not current deployment instructions. Do not infer
activation, availability, or safe recovery procedures from this overview.

The field-name-only secret template inventory is documented in
[security and secrets](architecture/security-and-secrets.md). It contains no
secret values and is not evidence that any named field is populated or active.
