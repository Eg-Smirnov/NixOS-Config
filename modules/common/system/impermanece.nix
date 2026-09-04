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
        ".ssh"         # <-- Вот эта строчка сохранит твою папку с ключами
        ".local/share/keyrings"
      ];
      files = [
        ".bash_history"
        "/var/lib/sops-nix/key.txt"
        "/etc/vpn/config.json"
        "~/.config/sops/age/keys.txt"
      ];
    };
  };
}