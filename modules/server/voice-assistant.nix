{ config, lib, pkgs, ... }:

let
  cfg = config.services.serverVoiceAssistant;

  generateTone = pkgs.writeShellScript "server-voice-generate-tone" ''
    exec ${pkgs.python3}/bin/python3 - <<'PY'
    import math
    import struct
    import wave

    with wave.open(${builtins.toJSON cfg.toneFile}, "wb") as wav:
        wav.setnchannels(2)
        wav.setsampwidth(2)
        wav.setframerate(48000)
        for sample in range(48000 * 2):
            value = int(14000 * math.sin(2 * math.pi * 440 * sample / 48000))
            wav.writeframesraw(struct.pack("<hh", value, value))
    PY
  '';

  playTone = pkgs.writeShellScript "server-voice-play-tone" ''
    exec ${pkgs.alsa-utils}/bin/aplay -D ${lib.escapeShellArg cfg.playbackDevice} ${cfg.toneFile}
  '';
in
{
  options.services.serverVoiceAssistant = {
    enable = lib.mkEnableOption "the local server voice assistant";

    wakeWord = lib.mkOption {
      type = lib.types.str;
      default = "hey_jarvis";
      description = "Temporary openWakeWord model name.";
    };

    captureDevice = lib.mkOption {
      type = lib.types.str;
      default = "plughw:1,0";
      description = "ALSA capture device.";
    };

    playbackDevice = lib.mkOption {
      type = lib.types.str;
      default = "plughw:1,0";
      description = "ALSA playback device.";
    };

    toneFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/server-voice/tone-440.wav";
      description = "WAV file played by the initial test scenario.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wakeWord != "";
        message = "services.serverVoiceAssistant.wakeWord must not be empty";
      }
    ];

    users.users.server-voice = {
      isSystemUser = true;
      group = "server-voice";
      extraGroups = [ "audio" ];
      description = "Least-privilege voice assistant service user";
    };
    users.groups.server-voice = { };

    environment.systemPackages = with pkgs; [
      alsa-utils
      home-assistant
      piper-tts
      wyoming-openwakeword
      wyoming-satellite
      python313Packages.faster-whisper
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/server-voice 0750 server-voice server-voice - -"
      "d /var/lib/server-voice/models 0750 server-voice server-voice - -"
    ];

    systemd.services.server-voice-tone = {
      description = "Generate the initial voice assistant test tone";
      wantedBy = [ "multi-user.target" ];
      before = [ "server-voice-satellite.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = generateTone;
        User = "server-voice";
        Group = "server-voice";
        StateDirectory = "server-voice";
      };
    };

    systemd.services.server-voice-openwakeword = {
      description = "Local openWakeWord Wyoming service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.wyoming-openwakeword}/bin/wyoming-openwakeword --uri tcp://127.0.0.1:10400 --debug";
        Restart = "on-failure";
        User = "server-voice";
        Group = "server-voice";
        SupplementaryGroups = [ "audio" ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/server-voice" ];
      };
    };

    systemd.services.server-voice-satellite = {
      description = "Local voice satellite for the server assistant";
      wantedBy = [ "multi-user.target" ];
      after = [ "server-voice-openwakeword.service" "server-voice-tone.service" ];
      wants = [ "server-voice-openwakeword.service" "server-voice-tone.service" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.wyoming-satellite}/bin/wyoming-satellite \
            --uri tcp://127.0.0.1:10500 \
            --name server \
            --mic-command "${pkgs.alsa-utils}/bin/arecord -D ${cfg.captureDevice} -f S16_LE -c 1 -r 16000" \
            --mic-command-rate 16000 \
            --mic-command-width 2 \
            --mic-command-channels 1 \
            --wake-uri tcp://127.0.0.1:10400 \
            --wake-word-name ${lib.escapeShellArg cfg.wakeWord} \
            --detection-command ${playTone} \
            --debug
        '';
        Restart = "on-failure";
        User = "server-voice";
        Group = "server-voice";
        SupplementaryGroups = [ "audio" ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/server-voice" ];
      };
    };

    systemd.services.home-assistant = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };

    services.home-assistant = {
      enable = true;
      openFirewall = false;
      config = {
        homeassistant = {
          name = "server";
          unit_system = "metric";
        };
        default_config = { };
      };
    };
  };
}
