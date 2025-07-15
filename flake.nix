{
  description = "Desktop shell for Caelestia dots";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    app2unit = {
      url = "github:soramanew/app2unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = fn:
      nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux (
        system: fn nixpkgs.legacyPackages.${system}
      );
  in {
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    packages = forAllSystems (pkgs: rec {
      caelestia-shell = pkgs.callPackage ./default.nix {
        rev = self.rev or self.dirtyRev;
        quickshell = inputs.quickshell.packages.${pkgs.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        app2unit = inputs.app2unit.packages.${pkgs.system}.default;
      };
      default = caelestia-shell;
    });

    # devShells = forAllSystems (pkgs: {
    #   default = let
    #     qtDeps = with pkgs.kdePackages; [
    #       inputs.quickshell.packages.${pkgs.system}.default
    #       qtbase
    #       qtdeclarative
    #     ];
    #     qmlPath = pkgs.lib.makeSearchPath "lib/qt-6/qml" qtDeps;
    #   in
    #     pkgs.mkShellNoCC {
    #       inputsFrom = [self.packages.${pkgs.system}.caelestia-shell];
    #       packages =
    #         qtDeps
    #         ++ [
    #           (inputs.caelestia-cli.packages.${pkgs.system}.default.override {
    #             discordBin = "equibop";
    #             qtctStyle = "Breeze";
    #           })
    #         ];
    #       shellHook = ''
    #         export QML2_IMPORT_PATH="$QML2_IMPORT_PATH:${qmlPath}"
    #       '';
    #     };
    # });
  };
}
