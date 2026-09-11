{ infrastructure, ... }:

{
  programs.ssh.knownHosts = {
    vps = {
      hostNames = [ infrastructure.vps.address ];
      publicKey = infrastructure.vps.hostKey;
    };

    # github = {
    #   hostNames = [ "github.com" ];
    #   publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."; # официальный ключ GitHub
    # };
  };
}