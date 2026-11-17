{ config, ... }:

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
  networking.wireguard.interfaces.awg-exit = {
    type = "amneziawg";
    ips = [ "10.200.0.2/30" ];
    listenPort = 30326;
    privateKeyFile = config.sops.secrets.awg_private_key.path;
    extraOptions = awgOptions;

    peers = [
      {
        name = "vps1-uplink";
        publicKey = "oZAUMpvIOon1Uaoz716rjop3tHHk6+d8L+490qyhDHc=";
        allowedIPs = [ "10.200.0.1/32" "10.201.0.0/24" ];
      }
    ];
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.nat = {
    enable = true;
    externalInterface = "ens3";
    internalInterfaces = [ "awg-exit" ];
  };
}
