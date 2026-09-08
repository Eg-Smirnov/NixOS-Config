{
  imports = [
    ./hardware-configuration.nix

    ../../modules/common/security/sops.nix
    ../../modules/common/security/ssh.nix
    ../../modules/common/security/known-hosts.nix

    ../../modules/common/system/impermanence.nix
    ../../modules/common/system/power.nix
    ../../modules/common/system/configuration.nix
    ../../modules/common/system/locale.nix

    ../../modules/common/users/users.nix

    ../../modules/common/networking/networking.nix
    ../../modules/common/networking/vpn/xray.nix
    ../../modules/common/networking/reverse-ssh.nix

    ../../modules/common/programs/git.nix

    ../../modules/server/media.nix
    ../../modules/server/torrent
    ../../modules/server/arrs/sonarr.nix
    ../../modules/server/arrs/radarr.nix
    ../../modules/server/arrs/prowlarr.nix
    
    ../../modules/server/jellyfin
  ];
}