self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  shell-default = self.packages.${system}.sitka-shell;

  cfg = config.programs.sitka;
in {
  options = with lib; {
    programs.sitka = {
      enable = mkEnableOption "Enable Sitka shell";
      package = mkOption {
        type = types.package;
        default = shell-default;
        description = "The package of Sitka shell";
      };
      systemd = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable the systemd service for Sitka shell";
        };
        target = mkOption {
          type = types.str;
          description = ''
            The systemd target that will automatically start the Sitka shell.
          '';
          default = config.wayland.systemd.target;
        };
        environment = mkOption {
          type = types.listOf types.str;
          description = "Extra Environment variables to pass to the Sitka shell systemd service.";
          default = [];
          example = [
            "QT_QPA_PLATFORMTHEME=gtk3"
          ];
        };
      };
      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Sitka shell settings";
      };
      extraConfig = mkOption {
        type = types.str;
        default = "";
        description = "Sitka shell extra configs written to shell.json";
      };
    };
  };

  config = let
    shell = cfg.package;
  in
    lib.mkIf cfg.enable {
      systemd.user.services.sitka-shell = lib.mkIf cfg.systemd.enable {
        Unit = {
          Description = "Sitka Shell Service";
          After = [cfg.systemd.target];
          PartOf = [cfg.systemd.target];
          X-Restart-Triggers = lib.mkIf (cfg.settings != {}) [
            "${config.xdg.configFile."sitka/shell.json".source}"
          ];
        };

        Service = {
          Type = "exec";
          ExecStart = "${shell}/bin/sitka-shell";
          Restart = "on-failure";
          RestartSec = "5s";
          TimeoutStopSec = "5s";
          Environment =
            [
              "QT_QPA_PLATFORM=wayland"
            ]
            ++ cfg.systemd.environment;

          Slice = "session.slice";
        };

        Install = {
          WantedBy = [cfg.systemd.target];
        };
      };

      xdg.configFile = let
        mkConfig = c:
          lib.pipe (
            if c.extraConfig != ""
            then c.extraConfig
            else "{}"
          ) [
            builtins.fromJSON
            (lib.recursiveUpdate c.settings)
            builtins.toJSON
          ];
      in {
        "sitka/shell.json".text = mkConfig cfg;
      };

      home.packages = [shell];
    };
}