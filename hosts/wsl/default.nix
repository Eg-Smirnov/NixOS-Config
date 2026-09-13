{ inputs, pkgs, ... }:

{
  # Включаем WSL-специфичные настройки (интероп, автомонтирование и т.д.)
  wsl.enable = true;
  wsl.defaultUser = "server"; 
  
  imports = [

    ./sops.nix
    ./ssh.nix
    ./known-hosts.nix
    ./impermanence.nix
    ../../modules/common/system/locale.nix

    ./users.nix
    ./networking.nix
    ../../modules/server/vpn/xray.nix
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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "26.05"; # Проверьте в своей системе: cat /etc/os-release

  # environment.systemPackages = [ pkgs.git ];
}
