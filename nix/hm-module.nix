self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  shell-default = self.packages.${system}.sitka-shell;

  cfg = config.programs.sitka;
  
  # Swayidle configuration
  swayidleCfg = cfg.swayidle;
  
  # Build IPC commands for swayidle
  screensaverEnableCmd = "${cfg.package}/bin/sitka-ipc call screensaver enable";
  activityDetectedCmd = "${cfg.package}/bin/sitka-ipc call screensaver activityDetected";
  dpmsOffCmd = "${cfg.package}/bin/sitka-ipc call screensaver dpmsOff";
  lockCmd = "${cfg.package}/bin/sitka-ipc call screensaver lock";
  
  # Build the complete swayidle command
  swayidleCmd = lib.concatStringsSep " " (
    [ "${pkgs.swayidle}/bin/swayidle -w" ]
    ++ lib.optional (swayidleCfg.screensaverTimeout > 0)
      "timeout ${toString swayidleCfg.screensaverTimeout} '${screensaverEnableCmd}'"
    ++ [ "resume '${activityDetectedCmd}'" ]
    ++ lib.optional (swayidleCfg.dpmsTimeout > 0)
      "timeout ${toString swayidleCfg.dpmsTimeout} '${dpmsOffCmd}'"
    ++ lib.optional swayidleCfg.lockOnSleep
      "before-sleep '${lockCmd}'"
  );
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
      
      # Swayidle integration for screensaver
      swayidle = {
        enable = mkEnableOption "swayidle integration for screensaver";
        
        screensaverTimeout = mkOption {
          type = types.int;
          default = 300;
          description = "Seconds of idle before triggering screensaver (0 to disable).";
        };
        
        dpmsTimeout = mkOption {
          type = types.int;
          default = 660;
          description = "Seconds of idle before turning off monitors (0 to disable).";
        };
        
        lockOnSleep = mkOption {
          type = types.bool;
          default = true;
          description = "Lock screen before system sleep/hibernate.";
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
      
      # Swayidle service for screensaver integration
      systemd.user.services.swayidle = lib.mkIf swayidleCfg.enable {
        Unit = {
          Description = "Idle manager for Wayland - sitka-shell screensaver integration";
          Documentation = "man:swayidle(1)";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
          Requisite = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = swayidleCmd;
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
      
      home.packages = [ shell ] ++ lib.optional swayidleCfg.enable pkgs.swayidle;

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
    };
}