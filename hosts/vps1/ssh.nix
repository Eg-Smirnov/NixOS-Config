{ infrastructure, ... }:

let
  media = infrastructure.vps.mediaGateway.services;
  permittedListeners = [
    "127.0.0.1:${toString infrastructure.vps.reverseTunnel.remotePort}"
    "127.0.0.1:${toString media.jellyfin.remotePort}"
    "127.0.0.1:${toString media.sonarr.remotePort}"
    "127.0.0.1:${toString media.radarr.remotePort}"
    "127.0.0.1:${toString media.prowlarr.remotePort}"
    "127.0.0.1:${toString media.qbittorrent.remotePort}"
  ];
  permitListen = builtins.concatStringsSep " " permittedListeners;
  authorizedKeyOptions = builtins.concatStringsSep "," (
    [ "restrict" "port-forwarding" ]
    ++ map (listener: ''permitlisten="${listener}"'') permittedListeners
  );
in
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PubkeyAuthentication = true;
      AllowUsers = [
        "server"
        "reverse-tunnel"
      ];
    };
    ports = [ 22 ];

    extraConfig = ''
      Match User reverse-tunnel
        AllowTcpForwarding remote
        AllowAgentForwarding no
        PermitTTY no
        PermitTunnel no
        PermitUserRC no
        PermitOpen none
        PermitListen ${permitListen}
        X11Forwarding no
    '';
  };

  users.users.server.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop"
  ];

  users.users.reverse-tunnel.openssh.authorizedKeys.keys = [
    ''${authorizedKeyOptions} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7b2nOkSTK62YFlQsx6/g2HkHWZLnlqfeEite93pmEg home-server-reverse-tunnel''
  ];
}
