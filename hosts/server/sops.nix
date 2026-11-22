{ config, secrets, ... }:
{
  sops = {
    defaultSopsFile = secrets + "/home-server.yaml";
    age = {
      keyFile = "${config.users.users.server.home}/.config/sops/age/keys.txt";
    };
  };

  sops.secrets.ssh_git_agent_key = {
    sopsFile = secrets + "/home-server.yaml";
    key = "ssh_git_agent_key";
    owner = "agent";
    group = "agent";
    mode = "0400";
  };
}
