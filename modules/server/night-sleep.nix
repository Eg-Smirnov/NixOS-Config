{ config, pkgs, ... }:

let
  checkJellyfinAndSuspend = pkgs.writeShellApplication {
    name = "check-jellyfin-and-suspend";
    runtimeInputs = [
      pkgs.python3
      pkgs.systemd
    ];
    text = ''
      if ! python3 - "${config.sops.secrets.jellyfin_api_sleep.path}" <<'PY'
      import json
      import pathlib
      import sys
      import urllib.request

      api_key = pathlib.Path(sys.argv[1]).read_text().strip()
      request = urllib.request.Request(
          "http://127.0.0.1:8096/Sessions?activeWithinSeconds=900",
          headers={"X-Emby-Token": api_key},
      )

      try:
          with urllib.request.urlopen(request, timeout=10) as response:
              sessions = json.load(response)
      except Exception as error:
          print(f"Jellyfin activity check failed; keeping the server awake: {error}")
          raise SystemExit(2)

      if not isinstance(sessions, list):
          print("Jellyfin returned an unexpected response; keeping the server awake")
          raise SystemExit(2)

      if sessions:
          print("Recent Jellyfin activity detected; keeping the server awake")
          raise SystemExit(1)

      print("No Jellyfin activity in the last 15 minutes; suspending")
      PY
      then
        exit 0
      fi

      systemctl suspend
    '';
  };
in
{
  sops.secrets.jellyfin_api_sleep = {
    owner = "root";
    mode = "0400";
  };

  systemd.services.night-sleep = {
    description = "Suspend the server at night when Jellyfin is idle";
    after = [ "jellyfin.service" ];
    wants = [ "jellyfin.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${checkJellyfinAndSuspend}/bin/check-jellyfin-and-suspend";
    };
  };

  systemd.timers.night-sleep = {
    description = "Check for an idle Jellyfin session during the night";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = [
        "*-*-* 00..07:00/5:00"
        "*-*-* 08:00,05,10,15,20,25:00"
      ];
      AccuracySec = "30s";
    };
  };

  systemd.services.morning-wake = {
    description = "No-op service for the morning RTC wake timer";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };

  systemd.timers.morning-wake = {
    description = "Wake the server every morning";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 08:30:00";
      AccuracySec = "1s";
      WakeSystem = true;
    };
  };
}
