{ config, lib, pkgs, ... }:

with lib;

let
  # Type for a valid systemd unit option. Needed for correctly passing "timerConfig" to "systemd.timers"
  unitOption = (import ../../system/boot/systemd-unit-options.nix { inherit config lib; }).unitOption;
in
{
  options.services.unison.jobs = mkOption {
    description = ''
      Periodic synchronization job with Unison
     '';
    type = types.attrsOf (types.submodule ({ name, ... }: {
      options = {
        source = mkOption {
          type = types.str;
          description = ''
            Source directory
          '';
          example = "source/";
        };

        destination = mkOption {
          type = types.str;
          description = ''
            Destination directory
          '';
          example = "ssh://somehost/shared/";
        };

        user = mkOption {
          type = types.str;
          default = "root";
          description = ''
            As which user the job should run.
          '';
          example = "root";
        };

        timerConfig = mkOption {
          type = types.attrsOf unitOption;
          default = {
            OnCalendar = "hourly";
          };
          description = ''
            When to run the synchronization. See man systemd.timer for details.
          '';
          example = {
            OnCalendar = "00:05";
            RandomizedDelaySec = "5h";
          };
        };
      };
    }));
    default = {};
    example = {
      remote = {
        source = "/home/user/shared";
        destination = "ssh://somehost/shared/";
        user = "user";
      };
    };
  };

  config = {
    systemd.services =
      mapAttrs' (name: job:
        let
          unisonCmd = "${pkgs.unison}/bin/unison -ui text -batch";
        in nameValuePair "unison-jobs-${name}" ({
          restartIfChanged = false;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${unisonCmd} ${job.source} ${job.destination}";
            User = job.user;
          };
        })
      ) config.services.unison.jobs;
    systemd.timers =
      mapAttrs' (name: job: nameValuePair "unison-jobs-${name}" {
        wantedBy = [ "timers.target" ];
        timerConfig = job.timerConfig;
      }) config.services.unison.jobs;
  };
}
