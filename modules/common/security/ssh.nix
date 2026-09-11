{ config, pkgs, infrastructure, ... }:

{
  sops.secrets.ssh_private_key = {
    owner = "server";
    group = "users";
    mode = "0400";
  };

  services.openssh = {
    enable = true;

    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;

      AllowUsers = [ "server" ];
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

  users.users.server.openssh.authorizedKeys.keys = [
    infrastructure.admin.publicKey
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];
}