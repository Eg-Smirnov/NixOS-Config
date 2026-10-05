{ ... }:

{
  networking.useDHCP = false;

  networking.interfaces.eth0 = {
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
    interface = "eth0";
  };
  networking.nameservers = [ "8.8.8.8" ];

  networking.firewall = {
    enable = true;

    # Port 2053 is temporary. Remove it immediately after the initial 3x-ui
    # setup; the final public cascade endpoint is 443/TCP.
    allowedTCPPorts = [
      22
      2053
    ];
  };
}
