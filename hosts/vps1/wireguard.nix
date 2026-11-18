{ config, pkgs, ... }:

let
  awgOptions = {
    Jc = 4;
    Jmin = 40;
    Jmax = 70;
    S1 = 15;
    S2 = 25;
    H1 = 173829456;
    H2 = 285374619;
    H3 = 396485721;
    H4 = 508596832;
  };
in

{
  networking.wireguard.interfaces = {
    awg-entry = {
      type = "amneziawg";
      ips = [ "10.201.0.1/24" ];
      listenPort = 30326;
      privateKeyFile = config.sops.secrets.awg_entry_private_key.path;
      extraOptions = awgOptions;

      peers = [
        {
          name = "phone";
          publicKey = "2fT52zXGoJPXeeme54h4pG2o3s7fkkZcXbvtFDyklww=";
          allowedIPs = [ "10.201.0.2/32" ];
        }
      ];
    };

    awg-uplink = {
      type = "amneziawg";
      ips = [ "10.200.0.1/30" ];
      privateKeyFile = config.sops.secrets.awg_uplink_private_key.path;
      allowedIPsAsRoutes = false;
      extraOptions = awgOptions;

      peers = [
        {
          name = "vps2-exit";
          publicKey = "Gdll955Hcxr94w7OAWlbocTpcVJMacGgzwFIT0VoUWc=";
          endpoint = "104.128.142.208:30326";
          allowedIPs = [ "0.0.0.0/0" ];
          persistentKeepalive = 25;
        }
      ];

      postSetup = ''
        ip route replace default dev awg-uplink table 100 metric 100
      '';
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.firewall.checkReversePath = "loose";

  systemd.services.awg-client-routing-policy = {
    description = "Fail-closed routing policy for AmneziaWG clients";
    wantedBy = [ "multi-user.target" ];
    before = [
      "wireguard-awg-entry.service"
      "wireguard-awg-uplink.service"
    ];
    path = [ pkgs.iproute2 pkgs.gnugrep ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ip route replace blackhole default table 100 metric 32767
      if ! ip rule show | grep -Fq "from 10.201.0.0/24 lookup 100"; then
        ip rule add priority 100 from 10.201.0.0/24 table 100
      fi
    '';
  };

  systemd.services.wireguard-awg-entry = {
    requires = [ "awg-client-routing-policy.service" ];
    after = [ "awg-client-routing-policy.service" ];
  };
}
