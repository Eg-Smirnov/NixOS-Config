{ ... }:

{
  networking.useDHCP = false;

  networking.interfaces.ens3.ipv4.addresses = [
    {
      address = "103.71.20.103";
      prefixLength = 24;
    }
  ];

  networking.defaultGateway = "103.71.20.1";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      2096
      7142
      35474
      52542
      53013
    ];
    allowedUDPPorts = [
      53013
    ];
  };
}
