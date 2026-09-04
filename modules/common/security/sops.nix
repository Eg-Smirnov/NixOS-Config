{ config, pkgs, inputs, ... }:
{
  sops = {
    defaultSopsFile = ../../../secrets.yaml;
    age = {
      # Указываем системе, где искать ключ для расшифровки
      keyFile = "~/.config/sops/age/keys.txt";
      # Или, если хочешь использовать твой текущий SSH ключ, можешь попробовать:
      # sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };
  };
}