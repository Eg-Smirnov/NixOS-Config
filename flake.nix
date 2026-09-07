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
    };
  };
}
