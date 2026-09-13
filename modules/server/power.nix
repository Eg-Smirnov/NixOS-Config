{ config, pkgs, lib, ... }:  # <-- добавил lib
{
  # Отключаем спячку и гибернацию через современный формат
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowSuspendThenHibernate = false;
    AllowHybridSleep = false;
  };

  # Настройки logind через современный формат
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # Отключаем графику полностью (экран не будет использоваться)
  services.xserver.enable = false;

  # Отключаем USB-автосуспенд (для стабильности)
  powerManagement.powertop.enable = false;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/autosuspend}="0"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/control}="on"
  '';

  # Дополнительная защита от засыпания
  systemd.targets.sleep.enable = false;
}