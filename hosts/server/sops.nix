{ config, secrets, ... }:
{
  sops = {
    defaultSopsFile = secrets + "/home-server.yaml";
    age = {
      keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";
    };
  };
}
