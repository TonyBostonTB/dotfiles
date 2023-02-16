{
  description = "NixOS configuration with flakes";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";                              # MacOS Package Management
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {                                                          # Official Hyprland flake
      url = "github:vaxerski/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, darwin, hyprland, ... }:

    let                                                                   # variables that can be used in the config files
      user = "tboston";
      location = "$HOME/.setup";

    in {                                                                  # Use above variables in ...
      nixosConfigurations = (                                             # NixOS configurations
        import ./hosts {                                                  # Imports ./hosts.default
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager user location hyprland;     # Also inherit home-manager so it does not need to be defined here
        }
      );
      darwinConfigurations = (                                            # Darwin Configurations
        import ./darwin {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager darwin user;
        }
      );

      homeConfigurations = (                                              # Non-NixOS configurations
        import ./nix {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager user;
        }
      );
    };
}
