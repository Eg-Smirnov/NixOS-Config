#!/usr/bin/env python3
"""Create a local AmneziaWG client profile and register its public peer."""

from __future__ import annotations

import argparse
import base64
import binascii
import fcntl
import ipaddress
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
CLIENTS_FILE = REPO_ROOT / "hosts" / "vps1" / "awg-clients.json"
PRIVATE_DATA_DIR = (
    Path.home() / ".local" / "share" / "nixos-config" / "awg-client-profiles"
)
NAME_PATTERN = re.compile(r"[a-zA-Z0-9][a-zA-Z0-9_-]{0,31}\Z")


class GeneratorError(Exception):
    pass


def validate_key(value: str, description: str) -> str:
    try:
        decoded = base64.b64decode(value, validate=True)
    except (ValueError, binascii.Error) as error:
        raise GeneratorError(f"{description} is not valid base64") from error
    if len(decoded) != 32:
        raise GeneratorError(f"{description} must decode to 32 bytes")
    return value


def load_config() -> dict[str, Any]:
    try:
        with CLIENTS_FILE.open(encoding="utf-8") as config_file:
            config = json.load(config_file)
    except (OSError, json.JSONDecodeError) as error:
        raise GeneratorError(f"cannot read {CLIENTS_FILE}: {error}") from error

    try:
        server = config["server"]
        clients = config["clients"]
        subnet = ipaddress.ip_network(server["client_subnet"], strict=True)
        server_ip = ipaddress.ip_interface(server["server_address"]).ip
        if not isinstance(subnet, ipaddress.IPv4Network):
            raise GeneratorError("client_subnet must be an IPv4 network")
        if server_ip not in subnet:
            raise GeneratorError("server_address must be inside client_subnet")
        if not isinstance(ipaddress.ip_address(server["public_endpoint"]), ipaddress.IPv4Address):
            raise GeneratorError("public_endpoint must be an IPv4 address")
        port = server["listen_port"]
        if isinstance(port, bool) or not isinstance(port, int) or not 1 <= port <= 65535:
            raise GeneratorError("listen_port must be between 1 and 65535")
        validate_key(server["public_key"], "server public key")
        if not isinstance(clients, list):
            raise GeneratorError("clients must be a JSON array")
        if not isinstance(server["dns"], list) or not server["dns"]:
            raise GeneratorError("server dns must be a non-empty JSON array")
        for dns_address in server["dns"]:
            ipaddress.ip_address(dns_address)
        if not isinstance(server["allowed_ips"], list) or not server["allowed_ips"]:
            raise GeneratorError("server allowed_ips must be a non-empty JSON array")
        for allowed_network in server["allowed_ips"]:
            ipaddress.ip_network(allowed_network, strict=False)
        if not isinstance(server["awg_options"], dict):
            raise GeneratorError("server awg_options must be a JSON object")

        names: set[str] = set()
        public_keys = {server["public_key"]}
        addresses = {server_ip}
        for client in clients:
            name = client["name"]
            if not isinstance(name, str) or not NAME_PATTERN.fullmatch(name):
                raise GeneratorError(f"invalid existing peer name: {client['name']!r}")
            if name.casefold() in names:
                raise GeneratorError(f"duplicate existing peer name: {name}")
            names.add(name.casefold())
            public_key = validate_key(
                client["public_key"], f"public key for {name}"
            )
            if public_key in public_keys:
                raise GeneratorError(f"duplicate existing public key: {name}")
            public_keys.add(public_key)
            address = ipaddress.ip_interface(client["address"])
            if (
                address.version != 4
                or address.network.prefixlen != 32
                or address.ip not in subnet
            ):
                raise GeneratorError(f"invalid client address for {name}")
            if address.ip in addresses:
                raise GeneratorError(f"duplicate client address: {address.ip}")
            addresses.add(address.ip)
    except (KeyError, TypeError, ValueError) as error:
        if isinstance(error, GeneratorError):
            raise
        raise GeneratorError(f"invalid client configuration: {error}") from error

    return config


def allocate_address(config: dict[str, Any]) -> str:
    server = config["server"]
    subnet = ipaddress.ip_network(server["client_subnet"], strict=True)
    server_ip = ipaddress.ip_interface(server["server_address"]).ip
    used = {
        ipaddress.ip_interface(client["address"]).ip
        for client in config["clients"]
    }

    for address in subnet.hosts():
        if address != server_ip and address not in used:
            return f"{address}/32"
    raise GeneratorError(f"no available client addresses in {subnet}")


def run_awg(arguments: list[str], input_text: str | None = None) -> str:
    try:
        result = subprocess.run(
            arguments,
            input=input_text,
            capture_output=True,
            check=False,
            text=True,
        )
    except FileNotFoundError as error:
        raise GeneratorError(
            "awg was not found; run this utility inside the documented nix shell"
        ) from error
    if result.returncode != 0:
        raise GeneratorError(f"{arguments[0]} failed; no key material was printed")
    return result.stdout.strip()


def make_keypair() -> tuple[str, str]:
    private_key = validate_key(run_awg(["awg", "genkey"]), "generated private key")
    public_key = validate_key(
        run_awg(["awg", "pubkey"], private_key + "\n"), "generated public key"
    )
    return private_key, public_key


def render_profile(
    config: dict[str, Any], private_key: str, address: str
) -> str:
    server = config["server"]
    lines = [
        "[Interface]",
        f"PrivateKey = {private_key}",
        f"Address = {address}",
        f"DNS = {', '.join(server['dns'])}",
    ]
    lines.extend(f"{key} = {value}" for key, value in server["awg_options"].items())
    lines.extend(
        [
            "",
            "[Peer]",
            f"PublicKey = {server['public_key']}",
            f"Endpoint = {server['public_endpoint']}:{server['listen_port']}",
            f"AllowedIPs = {', '.join(server['allowed_ips'])}",
            f"PersistentKeepalive = {server['persistent_keepalive']}",
            "",
        ]
    )
    return "\n".join(lines)


def write_profile(path: Path, contents: str) -> None:
    try:
        descriptor = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError as error:
        raise GeneratorError(f"profile already exists: {path}") from error
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as output:
            output.write(contents)
            output.flush()
            os.fsync(output.fileno())
        os.chmod(path, 0o600)
    except Exception:
        path.unlink(missing_ok=True)
        raise


def write_config_atomically(config: dict[str, Any]) -> None:
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=CLIENTS_FILE.parent,
            prefix=f".{CLIENTS_FILE.name}.",
            suffix=".tmp",
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
            json.dump(config, temporary_file, ensure_ascii=False, indent=2)
            temporary_file.write("\n")
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
        os.replace(temporary_path, CLIENTS_FILE)
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate a private AmneziaWG profile locally and add only its "
            "public peer data to hosts/vps1/awg-clients.json."
        )
    )
    parser.add_argument(
        "--name",
        required=True,
        help="peer name using letters, numbers, hyphens, or underscores",
    )
    return parser.parse_args()


def main() -> int:
    arguments = parse_args()
    if not NAME_PATTERN.fullmatch(arguments.name):
        print(
            "error: --name must start with a letter or number and contain "
            "at most 32 letters, numbers, hyphens, or underscores",
            file=sys.stderr,
        )
        return 2

    try:
        PRIVATE_DATA_DIR.mkdir(mode=0o700, parents=True, exist_ok=True)
        os.chmod(PRIVATE_DATA_DIR, 0o700)
        lock_path = PRIVATE_DATA_DIR / ".generator.lock"
        with lock_path.open("a", encoding="utf-8") as lock_file:
            os.chmod(lock_path, 0o600)
            fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)

            config = load_config()
            if any(
                client["name"].casefold() == arguments.name.casefold()
                for client in config["clients"]
            ):
                raise GeneratorError(f"peer name already exists: {arguments.name}")

            address = allocate_address(config)
            private_key, public_key = make_keypair()
            profile_path = PRIVATE_DATA_DIR / f"{arguments.name}.conf"
            profile = render_profile(config, private_key, address)

            write_profile(profile_path, profile)
            config["clients"].append(
                {
                    "name": arguments.name,
                    "public_key": public_key,
                    "address": address,
                }
            )
            try:
                write_config_atomically(config)
            except Exception:
                profile_path.unlink(missing_ok=True)
                raise

        print(f"Created peer {arguments.name} at {address}.")
        print(f"Private client profile: {profile_path}")
        print(f"Public peer record: {CLIENTS_FILE}")
        print("No Git operations or server activation were performed.")
        return 0
    except GeneratorError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    except OSError as error:
        print(f"error: filesystem operation failed: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
