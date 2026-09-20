{ config, pkgs, ... }:

let
  amneziawgGo = pkgs.amneziawg-go.overrideAttrs (finalAttrs: _: {
    version = "3.1.20260828";
    src = pkgs.fetchFromGitHub {
      owner = "amnezia-vpn";
      repo = "amneziawg-go";
      tag = "v${finalAttrs.version}";
      hash = "sha256-vZb72SA+6v8FXZX247K05yiVEBWpLqAAIyw6bEE4eUQ=";
    };
    vendorHash = "sha256-Y2dCwlKMVLrkzDcNKyCPxFJwMbCA2mQKkakvzwbamCY=";
  });

  amneziawgTools = pkgs.amneziawg-tools.overrideAttrs (finalAttrs: _: {
    version = "3.1.20260812";
    src = pkgs.fetchFromGitHub {
      owner = "amnezia-vpn";
      repo = "amneziawg-tools";
      tag = "v${finalAttrs.version}";
      hash = "sha256-6GEb41ERhR0Hg3RbSyIHdXPSKaxugoFCmFS5S0UiZso=";
    };
  });

  configPath = config.sops.secrets.amneziawg_config.path;
in
{
  sops.secrets.amneziawg_config = {
    path = "/run/secrets/awg0.conf";
    owner = "root";
    group = "root";
    mode = "0400";
    restartUnits = [ "amneziawg.service" ];
  };

  environment.systemPackages = [ amneziawgGo amneziawgTools ];

  systemd.services.amneziawg = {
    description = "AmneziaWG full-tunnel VPN";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    path = [
      amneziawgGo
      amneziawgTools
      pkgs.iproute2
      pkgs.openresolv
      pkgs.nftables
      pkgs.iptables
    ];

    environment.WG_QUICK_USERSPACE_IMPLEMENTATION =
      "${amneziawgGo}/bin/amneziawg-go";

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${amneziawgTools}/bin/awg-quick up ${configPath}";
      ExecStop = "${amneziawgTools}/bin/awg-quick down ${configPath}";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  systemd.services.amneziawg-watchdog = {
    description = "Check AmneziaWG interface and full-tunnel route";
    after = [ "amneziawg.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if ! ${pkgs.iproute2}/bin/ip link show awg0 >/dev/null 2>&1 ||
         ! ${pkgs.iproute2}/bin/ip -4 route get 1.1.1.1 | ${pkgs.gnugrep}/bin/grep -q 'dev awg0'; then
        ${pkgs.systemd}/bin/systemctl restart amneziawg.service
      fi
    '';
  };

  systemd.timers.amneziawg-watchdog = {
    description = "Check AmneziaWG connectivity every 30 seconds";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
      Unit = "amneziawg-watchdog.service";
    };
  };
}
