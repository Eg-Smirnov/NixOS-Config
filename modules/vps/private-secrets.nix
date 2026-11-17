{ config, lib, secrets, ... }:

{
  sops = {
    defaultSopsFile = secrets + "/${config.networking.hostName}.yaml";
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets = {
      awg_entry_private_key = lib.mkIf (config.networking.hostName == "vps1") {
        mode = "0400";
        restartUnits = [ "wireguard-awg-entry.service" ];
      };

      awg_uplink_private_key = lib.mkIf (config.networking.hostName == "vps1") {
        mode = "0400";
        restartUnits = [ "wireguard-awg-uplink.service" ];
      };

      awg_private_key = lib.mkIf (config.networking.hostName == "vps2") {
        mode = "0400";
        restartUnits = [ "wireguard-awg-exit.service" ];
      };
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
