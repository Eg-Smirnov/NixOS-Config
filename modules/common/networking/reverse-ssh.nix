{ config, pkgs, infrastructure, ... }:

{
  sops.secrets.reverse_tunnel_private_key = {
    owner = "server";
    group = "users";
    mode = "0400";
  };

  systemd.services.reverse-ssh = {
    description = "Reverse SSH tunnel to VPS";

    wantedBy = [ "multi-user.target" ];

    after = [
      "network-online.target"
      "sops-nix.service"
    ];

    wants = [
      "network-online.target"
    ];

    serviceConfig = {
      Type = "simple";

      ExecStart = pkgs.writeShellScript "reverse-ssh" ''
        exec ${pkgs.openssh}/bin/ssh \
          -N \
          -T \
          -o ExitOnForwardFailure=yes \
          -o ServerAliveInterval=30 \
          -o ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=yes \
          -o UserKnownHostsFile=/etc/ssh/ssh_known_hosts \
          -o IdentityFile=${config.sops.secrets.reverse_tunnel_private_key.path} \
          -o IdentitiesOnly=yes \
          -R 127.0.0.1:${toString infrastructure.vps.reverseTunnel.remotePort}:127.0.0.1:22 \
          -p ${toString infrastructure.vps.sshPort} \
          ${infrastructure.vps.reverseTunnel.user}@${infrastructure.vps.address}
      '';

      Restart = "always";
      RestartSec = "10s";

      # Туннелю не нужны никакие привилегии.
      User = "server";
      Group = "users";

      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };
}