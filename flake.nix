{
  description = "Niri-first Quickshell desktop shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixgl = {
      url = "github:guibou/nixGL";
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
      sitka-shell = pkgs.callPackage ./nix {
        rev =
          if self ? rev then self.rev
          else if self ? dirtyRev then self.dirtyRev
          else "local-dev";
        stdenv = pkgs.clangStdenv;
        # Sitka is Niri-first; opt into the Hyprland runtime only for a
        # consumer that actually runs Hyprland.
        hyprland = null;
        quickshell = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          withX11 = false;
          withI3 = false;
        };
        app2unit = pkgs.callPackage ./nix/app2unit.nix {inherit pkgs;};
      };
      debug = sitka-shell.override {debug = true;};

      arch = let
        nixGL = inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLDefault;
      in
        pkgs.writeShellScriptBin "sitka-shell" ''
          # Sitka shell wrapper with automatic OpenGL support for non-NixOS
          
          # Ensure QML paths and libraries are set for the plugin
          export QML2_IMPORT_PATH="${sitka-shell.plugin}/lib/qt6/qml''${QML2_IMPORT_PATH:+:''$QML2_IMPORT_PATH}"
          export LD_LIBRARY_PATH="${sitka-shell.extras}/lib''${LD_LIBRARY_PATH:+:''$LD_LIBRARY_PATH}"
          
          # Ensure system binaries are accessible for TLP/Power management
          export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"
          
          if [ ! -f /etc/NIXOS ] && [ -z "$NIXGL_IGNORE" ]; then
            exec ${nixGL}/bin/nixGL ${sitka-shell}/bin/sitka-shell "$@"
          else
            exec ${sitka-shell}/bin/sitka-shell "$@"
          fi
        '';

      default = sitka-shell;
    });

    devShells = forAllSystems (pkgs: {
      default = let
        shell = self.packages.${pkgs.stdenv.hostPlatform.system}.sitka-shell;
        qmlImportPath = pkgs.lib.concatStringsSep ":" [
          "${shell.plugin}/lib/qt6/qml"
          "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}"
        ];
      in
        pkgs.mkShell.override {stdenv = shell.stdenv;} {
          inputsFrom = [shell shell.plugin shell.extras];
          packages = with pkgs; [material-symbols iosevka qt6.qtdeclarative];
          QML_IMPORT_PATH = qmlImportPath;
          QML2_IMPORT_PATH = qmlImportPath;
          SITKA_LIB_DIR = "${shell.extras}/lib";
          SITKA_XKB_RULES_PATH = "${pkgs.xkeyboard-config}/share/xkeyboard-config-2/rules/base.lst";
        };
    });

    homeManagerModules.default = import ./nix/hm-module.nix self;
  };
}
