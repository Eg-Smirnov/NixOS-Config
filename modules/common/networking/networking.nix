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
				    id = "home-wifi";
				    type = "wifi";
				    autoconnect = true;
				  };

				  wifi = {
				    mode = "infrastructure";
				    ssid = "$wifi_ssid";
				  };

				  wifi-security = {
				    key-mgmt = "wpa-psk";
				    psk = "$wifi_psk";
				  };

				  ipv4 = {
				    method = "auto";
				    dns = "1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4";
				    ignore-auto-dns = true;
				  };
				};
	    };
	  };
	};
	networking.nameservers = [
	  "1.0.0.1"
	];
}