{ config, pkgs, ... }:
{
  sops.secrets = {
    "wifi_ssid" = { };
    "wifi_psk" = { };
  };

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager = {
	  enable = true;
	  ensureProfiles = {
	    # Опционально: можно хранить пароль в отдельном файле
	    # environmentFiles = [ "/path/to/secrets.env" ];
	    profiles = {
	      "home-wifi" = {
	        connection = {
	          id = "home-wifi"; # Имя профиля, которое ты увидишь в интерфейсе
	          type = "wifi";
	          autoconnect = true; # Автоматически подключаться при загрузке
	        };
	        wifi = {
	          mode = "infrastructure";
	          ssid = "$wifi_ssid"; # Название твоей сети
	        };
	        wifi-security = {
	          key-mgmt = "wpa-psk"; # Или "sae" для WPA3 [citation:1]
	          psk = "$wifi_psk";
	        };
	      };
	    };
	  };
	};
}