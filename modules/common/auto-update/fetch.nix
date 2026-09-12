{ pkgs, ... }:

let
  stateDir = "/var/lib/nixos-auto-update";
in
{
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
  ];

  systemd.services.nixos-update-fetch = {
    description = "Fetch NixOS update state from GitHub";

    path = with pkgs; [
      curl
      jq
      coreutils
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      UMask = "0077";
    };

    script = ''
      set -euo pipefail

      repo="Eg-Smirnov/NixOS-Config"
      branch="master"
      api="https://api.github.com/repos/$repo"
      github_file="${stateDir}/github"

      echo "NixOS update fetch: checking GitHub..."

      commit_json="$(
        curl --fail --silent --show-error --location \
          --retry 2 --retry-all-errors \
          --connect-timeout 10 --max-time 30 \
          -H "Accept: application/vnd.github+json" \
          "$api/commits/$branch"
      )"

      master_sha="$(
        jq -er '.sha | strings | select(test("^[0-9a-f]{40}$"))' <<< "$commit_json"
      )"

      master_message="$(
        jq -er '.commit.message | strings | split("\\n")[0]' <<< "$commit_json"
      )"

      echo "Current master: $master_sha"

      runs_json="$(
        curl --fail --silent --show-error --location \
          --retry 2 --retry-all-errors \
          --connect-timeout 10 --max-time 30 \
          -H "Accept: application/vnd.github+json" \
          "$api/actions/workflows/nixos.yml/runs?branch=$branch&event=push&per_page=20"
      )"

      run="$(
        echo "$runs_json" |
          jq -r --arg sha "$master_sha" '
            .workflow_runs
            | map(select(
                .head_sha == $sha
              ))
            | sort_by(.run_attempt, .updated_at)
            | last
          '
      )"

      if [ "$run" = "null" ]; then
        ci_status="not_found"
        ci_conclusion="null"
        ci_url=""
        echo "CI: no NixOS CI run found for $master_sha"
      else
        ci_status="$(jq -er '.status | strings' <<< "$run")"
        ci_conclusion="$(jq -r '.conclusion // "null"' <<< "$run")"
        ci_url="$(jq -er '.html_url | strings' <<< "$run")"

        echo "CI status: $ci_status"
        echo "CI conclusion: $ci_conclusion"
        echo "CI run: $ci_url"
      fi

      checked_at="$(date --iso-8601=seconds)"

      tmp_file="${stateDir}/github.tmp"

      jq -n \
        --arg master_sha "$master_sha" \
        --arg master_message "$master_message" \
        --arg ci_status "$ci_status" \
        --arg ci_conclusion "$ci_conclusion" \
        --arg ci_url "$ci_url" \
        --arg checked_at "$checked_at" \
        '{ master_sha, master_message, ci_status, ci_conclusion, ci_url, checked_at }' \
        > "$tmp_file"

      mv "$tmp_file" "$github_file"

      echo "GitHub state saved to $github_file"
    '';
  };

  systemd.timers.nixos-update-fetch = {
    description = "Fetch NixOS update state from GitHub";

    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "5min";
      Unit = "nixos-update-fetch.service";
    };
  };
}
