{ inputs, ... }:

{
  # Включаем WSL-специфичные настройки (интероп, автомонтирование и т.д.)
  wsl.enable = true;
  # Если вы используете WSLg (GUI приложения в Windows 11), раскомментируйте:
  # wsl.wslg.enable = true;

  # Включаем flakes, чтобы nixos-rebuild работал с вашим flake.nix
  # nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Убедитесь, что здесь указан system.stateVersion, соответствующий вашей базовой установке.
  # Обычно это версия, которая была при первой установке NixOS-WSL.
  system.stateVersion = "26.05"; # Проверьте в своей системе: cat /etc/os-release
}