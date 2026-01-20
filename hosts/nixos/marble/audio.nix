{
  pkgs,
  lib,
  ...
}:
let
  jackWrap =
    drv:
    pkgs.symlinkJoin {
      name = "${drv.name}-jackwrapped";
      paths = [ drv ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        ls "$out/bin"
        for b in "$out/bin/"*; do
          wrapProgram "$b" \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        done
      '';
    };
in
{
  home.packages = with pkgs; [
    pwvucontrol
    pavucontrol

    (jackWrap carla)

    (yabridge.override { wineWow64Packages = wineWow64Packages; })
    (yabridgectl.override { wineWow64Packages = wineWow64Packages; })
    wineWow64Packages.yabridge
  ];

  home.file.".config/pipewire/pipewire.conf.d/realtime.conf" = {
    text = ''
      module.rt.args = {
        nice.level = -11
        rt.prio = 80
      }
    '';
  };

  home.file.".config/pipewire/pipewire.conf.d/replay-setup.conf" = {
    text = ''
      context.modules = [
        {
          name = libpipewire-module-loopback
          args = {
            node.description = "Carla mic"
            capture.props = {
              node.name = "carla-mic-output"
              node.description = "Carla mic output"
              audio.position = [ FL ]
              node.passive = true
            }
            playback.props = {
              node.name = "Carla mic input"
              media.class = "Audio/Source"
              audio.position = [ MONO ]
            }
          }
        }
      	{
      		name = libpipewire-module-loopback
      		args = {
      			node.description = "Discord Audio Capture"
      			audio.position = [ FL FR ]
      			capture.props = {
      				node.name = "discord-audio-sink"
      				media.class = "Audio/Sink"
      				node.description = "Discord Audio Capture"
      				device.description = "Discord Audio Capture"
      				device.class = "sound"
      				device.icon-name = "audio-card"
      				node.virtual = false
      			}
      			playback.props = {
      				node.name = "discord-audio-monitor"
      				node.description = "Discord Audio Capture Monitor"
      				node.passive = true
      			}
      		}
      	}
      	{
      		name = libpipewire-module-loopback
      		args = {
      			node.description = "Desktop Audio Capture"
      			audio.position = [ FL FR ]
      			capture.props = {
      				node.name = "desktop-audio-sink"
      				media.class = "Audio/Sink"
      				node.description = "Desktop Audio Capture"
      				device.description = "Desktop Audio Capture"
      				device.class = "sound"
      				device.icon-name = "audio-card"
      				node.virtual = false
      			}
      			playback.props = {
      				node.name = "desktop-audio-monitor"
      				node.description = "Desktop Audio Capture Monitor"
      				node.passive = true
      			}
      		}
      	}
      	{
      		name = libpipewire-module-loopback
      		args = {
      			node.description = "Music Capture"
      			audio.position = [ FL FR ]
      			capture.props = {
      				node.name = "discord-audio-sink"
      				media.class = "Audio/Sink"
      				node.description = "Music Capture"
      				device.description = "Music Capture"
      				device.class = "sound"
      				device.icon-name = "audio-card"
      				node.virtual = false
      			}
      			playback.props = {
      				node.name = "discord-audio-monitor"
      				node.description = "Music Capture Monitor"
      				node.passive = true
      			}
      		}
      	}
      ]   
    '';
  };

  systemd.user.services = {
    carla-autorun = {
      Unit = {
        Description = "carla vst";
        After = [ "pipewire.service" ];
      };

      Service = {
        Type = "exec";
        Environment = [
          "NIX_PROFILES=\"${pkgs.yabridge} $NIX_PROFILES\""
        ];
        ExecStart = "${lib.getExe pkgs.carla} /home/kate/mic.carxp";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
