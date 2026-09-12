{
  vps = {
    address = "104.128.142.208";
    sshPort = 22;

    hostKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCzBAQIVPdn0sILHVQpdDgTUSNtmpxOAl8XP1hWhxkfXlG7z1jP1uDN9rYrpf1QrxMKUvH95v5l/Y6HOwNXSZvFNQYp6lOrOBAO3UCr3BNdtrA2+gJs9r9Zolb0wZBzdpyaRzQlbDgxn+H1WaN0wKGxapFEdZ+oAo82+sUsbFbyXltMvLcy9Y4Cj6Vt64VODfyUrb/cZ+13DhghHbmt/GZ5Y/djLnQi3ryQ7RAll9MihDiyHP3+VUS6AmEflRDD5DJ1lAR4/Gdpc+tjdEzpN4UvsCmjSjuhTT4py6eYg5Vzrq01rvIegMfRFnUhsZLw76LKIk68+eqFybKG6vgyfVl5y8WQlurtdxHlUbOzET9hSqWuGAEMz/AqlyKqzU2Vi/qWni0cSuSWJu8AH0S1YMKWlLpeZIjwQVrLU/Qb1AVq5TkMvAtF4UmGoE1U8RfGVYXPajgfg2HGEbFUaclgaeKIAlk+jdssGijREBzD0sJIhA6e0lZUtQh6gb3bSlzmA90=";

    reverseTunnel = {
      user = "reverse-tunnel";
      remotePort = 22022;
    };
  };

  admin = {
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFbguy5Xd0uBsN7azv2O4AmjWHUebZz8EbVVwm3Me8n egor@Egors-laptop";
  };
}
