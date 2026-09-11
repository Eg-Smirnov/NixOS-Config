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

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      # Следуем за вашим nixpkgs, чтобы версии были согласованы
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };

  outputs = { self, nixpkgs, impermanence, sops-nix, nixos-wsl }: {
    nixosConfigurations = {
      server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        specialArgs = {
          infrastructure = import ./hosts/server/infrastructure.nix;
        };
        
        modules = [
          ./hosts/server

          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops
        ];
      };

      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # WSL работает на x86_64

        specialArgs = {
          infrastructure = import ./hosts/wsl/infrastructure.nix;
        };


        modules = [
          # Указываем путь к вашему новому файлу конфигурации
          nixos-wsl.nixosModules.default
          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops

          ./hosts/wsl
        ];
      };
    };
  };
}
