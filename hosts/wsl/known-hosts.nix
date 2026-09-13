{ infrastructure, ... }:

{
  programs.ssh.knownHosts.vps = {
    hostNames = [ infrastructure.vps.address ];
    publicKey = infrastructure.vps.hostKey;
  };
}
