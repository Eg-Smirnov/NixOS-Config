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

    # 443/TCP is the public cascade endpoint. The 3x-ui panel uses 3452/TCP.
    allowedTCPPorts = [
      22
      443
      3452
    ];
  };
}
