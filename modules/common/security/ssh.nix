{ config, pkgs, ... }:
{
	services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
    ports = [ 22 ];
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];

}