{ config, ... }:

{
  networking.wireguard.interfaces.wg-cascade = {
    ips = [ "10.200.0.2/30" ];
    privateKeyFile = config.sops.secrets.wireguard_private_key.path;

    peers = [
      {
        publicKey = "maD0yhiCzAvjM5yEnK7xzUCjG9YWwvYKzv2h5ZALb3U=";
        allowedIPs = [ "10.200.0.1/32" ];
        endpoint = "103.71.20.103:51820";
        persistentKeepalive = 25;
      }
    ];
  };

  systemd.services."wireguard-wg-cascade" = {
    requires = [ "sops-nix.service" ];
    after = [ "sops-nix.service" ];
  };
}
