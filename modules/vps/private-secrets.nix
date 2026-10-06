{ config, secrets, ... }:

{
  sops = {
    defaultSopsFile = secrets + "/${config.networking.hostName}.yaml";
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets.wireguard_private_key = {
      mode = "0400";
      restartUnits = [ "wireguard-wg-cascade.service" ];
    };
  };

  programs.ssh = {
    extraConfig = ''
      Host github.com
        IdentityFile /persist/var/lib/nixos-secrets-git/id_ed25519
        IdentitiesOnly yes
    '';

    knownHosts.github = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
  };
}
