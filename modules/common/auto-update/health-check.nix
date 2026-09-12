{ pkgs, ... }:

let
  stateDir = "/var/lib/nixos-auto-update";
in
{
  systemd.services.nixos-health-check = {
    description = "NixOS health check";

    path = with pkgs; [
      coreutils
      jq
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      UMask = "0077";
    };

    script = ''
      set -euo pipefail

      echo "NixOS health check"

      critical=0
      major=0
      minor=0
      errors='[]'

      # Checks will be added here.

      checked_at="$(date --iso-8601=seconds)"
      tmp_file="${stateDir}/health.tmp"

      jq -n \
        --arg checked_at "$checked_at" \
        --argjson critical "$critical" \
        --argjson major "$major" \
        --argjson minor "$minor" \
        --argjson errors "$errors" \
        '{ checked_at, critical, major, minor, errors }' \
        > "$tmp_file"

      mv "$tmp_file" "${stateDir}/health"

      echo "Health result: critical=$critical major=$major minor=$minor"

      if (( critical > 0 )); then
        exit 2
      elif (( major > 0 )); then
        exit 1
      fi
    '';
  };
}
