{ ... }:

{
  networking.useDHCP = false;

  networking.interfaces.ens3 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "104.128.142.208";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "104.128.142.1";
    interface = "ens3";
  };
  networking.nameservers = [ "8.8.8.8" ];

  networking.firewall = {
    enable = true;

    # 443/TCP and 443/UDP are public cascade endpoints. The 3x-ui panel uses
    # 3452/TCP.
    allowedTCPPorts = [
      22
      443
      3452
    ];
    allowedUDPPorts = [ 443 ];
  };
}
