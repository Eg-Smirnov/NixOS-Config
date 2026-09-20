{
  imports = [
    ./hardware-configuration.nix

    ./sops.nix
    ./ssh.nix
    ./known-hosts.nix
    ./impermanence.nix
    ./boot.nix
    ../../modules/common/system/locale.nix

    # Disabled while automatic updates are under development.
    # ../../modules/server/auto-update

    ./users.nix
    ./networking.nix
    # Enable after amneziawg_config has been added to encrypted secrets.yaml.
    # ../../modules/server/vpn/amneziawg.nix
    ../../modules/server/reverse-ssh.nix

    ../../modules/common/programs/git.nix

    ../../modules/server/media.nix
    ../../modules/server/torrent
    ../../modules/server/arrs/sonarr.nix
    ../../modules/server/arrs/radarr.nix
    ../../modules/server/arrs/prowlarr.nix
    ../../modules/server/arrs/flaresolverr.nix
    
    ../../modules/server/jellyfin
    ../../modules/server/power.nix
  ];
}
