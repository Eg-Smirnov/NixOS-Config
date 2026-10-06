{ config, ... }:

{
  networking.wireguard.interfaces.wg-cascade = {
    ips = [ "10.200.0.1/30" ];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets.wireguard_private_key.path;

    peers = [
      {
        publicKey = "sk7Tu3mGg21kwUvKgra3G8bily8uT0rR02u0Gs6haAw=";
        allowedIPs = [ "10.200.0.2/32" ];
      }
    ];
  };

  systemd.services."wireguard-wg-cascade" = {
    requires = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
  };
}
