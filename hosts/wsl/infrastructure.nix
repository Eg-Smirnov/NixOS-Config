{
  vps = {
    address = "103.71.20.103";
    sshPort = 22;

    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUxH6Cc7MS6Rwq8vDEjEJyPyJ/6f/XA2+PWpn8GdoNr root@ubuntu";

    reverseTunnel = {
      user = "reverse-tunnel";
      remotePort = 22023;
    };
  };

  admin = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop";
  };
}