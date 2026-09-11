{ inputs, pkgs, ... }:

{
  # Включаем WSL-специфичные настройки (интероп, автомонтирование и т.д.)
  wsl.enable = true;
  wsl.defaultUser = "server"; 
  
  imports = [

    ../../modules/common/security/sops.nix
    ../../modules/common/security/ssh.nix
    ../../modules/common/security/known-hosts.nix

    ../../modules/common/system/impermanence.nix
    ../../modules/common/system/power.nix
    # ../../modules/common/system/configuration.nix
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
    ../../modules/server/arrs/flaresolverr.nix
    
    ../../modules/server/jellyfin

  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05"; # Проверьте в своей системе: cat /etc/os-release

  # environment.systemPackages = [ pkgs.git ];
}