{ pkgs, ... }:

let
  stateDir = "/var/lib/nixos-auto-update";
in
{
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
  ];

  systemd.services.nixos-auto-update = {
    description = "NixOS automatic update";

    path = with pkgs; [
      curl
      jq
      coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

    script = ''
      set -euo pipefail

      repo="Eg-Smirnov/NixOS-Config"
      branch="master"
      api="https://api.github.com/repos/$repo"

      echo "NixOS auto-update: checking GitHub..."

      # Get current master commit
      commit_json="$(
        curl -fsSL \
          -H "Accept: application/vnd.github+json" \
          "$api/commits/$branch"
      )"

      master_sha="$(
        echo "$commit_json" | jq -r '.sha'
      )"

      master_message="$(
        echo "$commit_json" | jq -r '.commit.message' | head -n 1
      )"

      echo "Current master: $master_sha"
      echo "Commit: $master_message"

      # Find the CI run for exactly this commit
      runs_json="$(
        curl -fsSL \
          -H "Accept: application/vnd.github+json" \
          "$api/actions/runs?branch=$branch&per_page=20"
      )"

      run="$(
        echo "$runs_json" |
          jq -r --arg sha "$master_sha" '
            .workflow_runs
            | map(select(
                .head_sha == $sha
                and .name == "NixOS CI"
              ))
            | sort_by(.created_at)
            | last
          '
      )"

      if [ "$run" = "null" ]; then
        echo "CI: no NixOS CI run found for $master_sha"
        exit 0
      fi

      ci_status="$(echo "$run" | jq -r '.status')"
      ci_conclusion="$(echo "$run" | jq -r '.conclusion')"
      ci_url="$(echo "$run" | jq -r '.html_url')"

      echo "CI status: $ci_status"
      echo "CI conclusion: $ci_conclusion"
      echo "CI run: $ci_url"

      if [ "$ci_status" = "completed" ] && [ "$ci_conclusion" = "success" ]; then
        echo "CI: SUCCESS"
      elif [ "$ci_status" != "completed" ]; then
        echo "CI: still running"
      else
        echo "CI: FAILED"
      fi

      echo "Auto-update action: NONE (monitoring only)"

      # Show current stored state, but do not modify it.
      if [ -f "${stateDir}/state" ]; then
        echo "Stored state:"
        cat "${stateDir}/state"
      else
        echo "Stored state: not initialized"
      fi
    '';
  };

  systemd.timers.nixos-auto-update = {
    description = "Check for NixOS updates";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "nixos-auto-update.service";
    };
  };
}