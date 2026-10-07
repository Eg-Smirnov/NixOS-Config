{ ... }:

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
        PermitListen 127.0.0.1:22022
        X11Forwarding no
    '';
  };

  users.users.server.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop"
  ];

  users.users.reverse-tunnel.openssh.authorizedKeys.keys = [
    ''restrict,port-forwarding,permitlisten="127.0.0.1:22022" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7b2nOkSTK62YFlQsx6/g2HkHWZLnlqfeEite93pmEg home-server-reverse-tunnel''
  ];
}
