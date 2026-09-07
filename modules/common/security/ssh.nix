{ config, pkgs, ... }:

{
  sops.secrets.ssh_private_key = {
    owner = "server";
    group = "users";
    mode = "0400";
  };

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = true;
    };

    ports = [ 22 ];
  };

  programs.ssh = {
    extraConfig = ''
      Host github.com
        IdentityFile /run/secrets/ssh_private_key
        IdentitiesOnly yes
    '';
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}