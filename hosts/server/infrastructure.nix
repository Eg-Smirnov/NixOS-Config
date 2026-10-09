{
  vps = {
    address = "103.71.20.103";
    sshPort = 22;

    hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKhODD+NLW+IU4VJ20F+obQpqepGLdp0L699eVPz90OR";

    reverseTunnel = {
      user = "reverse-tunnel";
      remotePort = 22022;
    };

    mediaGateway = {
      domain = "aboba-server.ru";
      acmeEmail = "egor.smirnov.n1@gmail.com";

      services = {
        jellyfin = {
          hostName = "jellyfin.aboba-server.ru";
          remotePort = 18096;
          localPort = 8096;
        };
        sonarr = {
          hostName = "sonarr.aboba-server.ru";
          remotePort = 18989;
          localPort = 8989;
        };
        radarr = {
          hostName = "radarr.aboba-server.ru";
          remotePort = 17878;
          localPort = 7878;
        };
        prowlarr = {
          hostName = "prowlarr.aboba-server.ru";
          remotePort = 19696;
          localPort = 9696;
        };
        qbittorrent = {
          hostName = "qbit.aboba-server.ru";
          remotePort = 18080;
          localPort = 8080;
        };
      };
    };
  };

  admin = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop";
  };
}
