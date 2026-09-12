{ pkgs, ... }:

let
  stateDir = "/var/lib/nixos-auto-update";
in
{
  systemd.tmpfiles.rules = [
    "d ${stateDir} 0700 root root -"
    "f ${stateDir}/state 0600 root root -"
    "f ${stateDir}/bad-commits 0600 root root -"
  ];

  systemd.services.nixos-auto-update = {
    description = "NixOS automatic update";

    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };

    script = ''
      echo "NixOS auto-update: not implemented yet"
      echo "State:"
      ${pkgs.coreutils}/bin/cat ${stateDir}/state
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

  system.activationScripts.nixos-auto-update-state.text = ''
    if [ ! -s "${stateDir}/state" ]; then
      cat > "${stateDir}/state" <<'EOF'
last_good_generation=52
last_good_commit=6eb902cbcd79d88bb92fdd95d9cc0a9529a86e89
EOF
    fi
  '';
}