{ config, pkgs, ... }:
{
  sops.secrets."vpn_config" = { };

  # Записать расшифрованный конфиг в файл
  systemd.tmpfiles.rules = [
    "f /etc/vpn/config.json 0644 root root - ${config.sops.secrets.vpn_config.path}"
  ];

  
}