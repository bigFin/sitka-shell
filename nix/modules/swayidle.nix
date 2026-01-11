# Swayidle integration for sitka-shell screensaver
#
# This module sets up swayidle to work with sitka-shell's ScreensaverService.
# It sends IPC commands to sitka-shell on idle timeouts instead of spawning
# external processes directly.
#
# Usage in your home.nix or home-manager module:
#   imports = [ inputs.sitka-shell.homeManagerModules.swayidle ];
#   services.sitka-swayidle = {
#     enable = true;
#     screensaverTimeout = 300;
#     dpmsTimeout = 660;
#   };
#
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.services.sitka-swayidle;
  
  # sitka-shell package - must be provided via overlay or direct reference
  # In practice, users will need to ensure sitka-shell is available
  sitkaShell = cfg.package;
  
  # Build IPC commands
  screensaverEnableCmd = "${sitkaShell}/bin/sitka-ipc call screensaver enable";
  activityDetectedCmd = "${sitkaShell}/bin/sitka-ipc call screensaver activityDetected";
  dpmsOffCmd = "${sitkaShell}/bin/sitka-ipc call screensaver dpmsOff";
  lockCmd = "${sitkaShell}/bin/sitka-ipc call screensaver lock";
  
  # Build the complete swayidle command
  swayidleCmd = concatStringsSep " " (
    [ "${pkgs.swayidle}/bin/swayidle -w" ]
    ++ optional (cfg.screensaverTimeout > 0)
      "timeout ${toString cfg.screensaverTimeout} '${screensaverEnableCmd}'"
    ++ [ "resume '${activityDetectedCmd}'" ]
    ++ optional (cfg.dpmsTimeout > 0)
      "timeout ${toString cfg.dpmsTimeout} '${dpmsOffCmd}'"
    ++ optional cfg.lockOnSleep
      "before-sleep '${lockCmd}'"
  );
in {
  options.services.sitka-swayidle = {
    enable = mkEnableOption "swayidle integration for sitka-shell screensaver";
    
    package = mkOption {
      type = types.package;
      description = "The sitka-shell package to use for IPC commands.";
    };
    
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
  
  config = mkIf cfg.enable {
    home.packages = [ pkgs.swayidle ];
    
    systemd.user.services.swayidle = {
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
  };
}
