{
  description = "Моя NixOS конфигурация";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, impermanence }: {
    nixosConfigurations = {
      # Имя хоста — укажи своё (то, что в /etc/hostname)
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          impermanence.nixosModules.impermanence
          ./hardware-configuration.nix
          ./configuration.nix
        ];
      };
    };
  };
}
