{
  vps = {
    address = "103.71.20.103";
    sshPort = 22;

    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhODD+NLW+IU4VJ20F+obQpqepGLdp0L699eVPz90OR";

    reverseTunnel = {
      user = "reverse-tunnel";
      remotePort = 22022;
    };
  };

  admin = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop";
  };
}
