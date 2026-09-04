{
  description = "Моя NixOS конфигурация";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";  # Использует ту же версию nixpkgs
    };
  };

  outputs = { self, nixpkgs, impermanence, sops-nix }: {
    nixosConfigurations = {
      # Имя хоста — укажи своё (то, что в /etc/hostname)
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/server/hardware-configuration.nix

          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops
 
          ./modules/common/security/sops.nix
          ./modules/common/security/ssh.nix

          ./modules/common/system/power.nix
          ./modules/common/system/configuration.nix
          ./modules/common/system/locale.nix
          ./modules/common/users/users.nix

          ./modules/common/networking/networking.nix
          ./modules/common/networking/vpn/xray.nix

        ];
      };
    };
  };
}
