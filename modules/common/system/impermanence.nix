{ config, pkgs, ... }:
{
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/lib"
      "/etc/NetworkManager/system-connections"
    ];

    users.server = {
      directories = [
        ".local/share/keyrings"
      ];

      files = [
        ".bash_history"
        ".config/sops/age/keys.txt"
      ];
    };
  };
}