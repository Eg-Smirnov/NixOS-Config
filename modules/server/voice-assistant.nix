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

  eventHandler = pkgs.writers.writePython3Bin "server-voice-event-handler" {
    libraries = [
      pkgs.python313Packages.faster-whisper
      pkgs.python313Packages.wyoming
    ];
    flakeIgnore = [ "E501" "W503" ];
  } ''
    import asyncio
    import pathlib
    import subprocess
    import wave

    from faster_whisper import WhisperModel
    from wyoming.audio import AudioChunk, AudioStart, AudioStop
    from wyoming.client import AsyncClient
    from wyoming.wake import Detect, Detection

    model = WhisperModel("${cfg.whisperModel}", device="cpu", compute_type="int8")


    def speak(text):
        tts_file = pathlib.Path("/run/server-voice/response.wav")
        subprocess.run(
            [
                "${pkgs.piper-tts}/bin/piper",
                "-m", "${cfg.piperModel}",
                "-c", "${cfg.piperModel}.json",
                "-f", str(tts_file),
            ], input=text + "\\n", text=True, check=True
        )
        subprocess.run(
            ["${pkgs.alsa-utils}/bin/aplay", "-D", "${cfg.playbackDevice}",
             str(tts_file)], check=True
        )


    async def process_audio(audio_start, audio):
        sample = pathlib.Path("/run/server-voice/command.wav")
        with wave.open(str(sample), "wb") as wav:
            wav.setnchannels(audio_start.channels)
            wav.setsampwidth(audio_start.width)
            wav.setframerate(audio_start.rate)
            wav.writeframes(audio)
        segments, _ = model.transcribe(
            str(sample), language="ru", vad_filter=True
        )
        transcript = " ".join(
            segment.text.strip() for segment in segments
        ).strip()
        print(f"transcript: {transcript!r}", flush=True)
        if transcript.lower() == "тон":
            subprocess.run(["${playTone}"], check=True)
        else:
            speak("Я услышал: " + (transcript or "тишину"))


    async def main():
        while True:
            try:
                async with AsyncClient.from_uri("tcp://127.0.0.1:10500") as client:
                    await client.write_event(
                        Detect(names=["${cfg.wakeWord}"]).event()
                    )
                    audio = bytearray()
                    audio_start = None
                    while True:
                        event = await client.read_event()
                        if event is None:
                            break
                        if Detection.is_type(event.type):
                            print("wake word detected", flush=True)
                            audio_start = AudioStart(rate=16000, width=2, channels=1)
                            audio.clear()
                        elif AudioStart.is_type(event.type):
                            audio_start = AudioStart.from_event(event)
                            audio.clear()
                            print(
                                f"audio start: {audio_start.rate}Hz "
                                f"{audio_start.channels}ch",
                                flush=True,
                            )
                        elif AudioChunk.is_type(event.type):
                            audio.extend(AudioChunk.from_event(event).audio)
                            if len(audio) % 16384 == 0:
                                print(f"audio bytes: {len(audio)}", flush=True)
                            if (
                                audio_start is not None
                                and len(audio)
                                >= audio_start.rate * audio_start.width
                                * audio_start.channels * 5
                            ):
                                await process_audio(audio_start, audio)
                                break
                        elif AudioStop.is_type(event.type) and audio_start is not None:
                            await process_audio(audio_start, audio)
                            break
            except Exception as error:
                print(f"voice event handler disconnected: {error}", flush=True)
                await asyncio.sleep(2)

    asyncio.run(main())
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

    piperModel = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/server-voice/models/ru_RU-dmitri-medium.onnx";
      description = "Path to the Piper ONNX voice model.";
    };

    whisperModel = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/server-voice/models/whisper-base";
      description = "Path to the local faster-whisper model directory.";
    };

    lva.enable = lib.mkEnableOption "Linux Voice Assistant Home Assistant satellite";
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
      uid = 995;
      group = "server-voice";
      extraGroups = [ "audio" "pipewire" ];
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
      "d /var/lib/server-voice/lva 0750 server-voice server-voice - -"
      "Z /var/lib/server-voice/lva 0750 server-voice server-voice - -"
      "d /var/lib/server-voice/lva/wakewords 0750 server-voice server-voice - -"
      "d /var/lib/server-voice/lva/sounds 0750 server-voice server-voice - -"
      "d /var/lib/server-voice/lva/local 0750 server-voice server-voice - -"
    ];

    services.pipewire = lib.mkIf cfg.lva.enable {
      enable = true;
      systemWide = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    virtualisation.docker.enable = lib.mkIf cfg.lva.enable true;
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.linux-voice-assistant = lib.mkIf cfg.lva.enable {
      image = "ghcr.io/ohf-voice/linux-voice-assistant:latest";
      autoStart = true;
      extraOptions = [
        "--network=host"
        "--group-add=${toString config.users.groups.audio.gid}"
        "--group-add=${toString config.users.groups.pipewire.gid}"
      ];
      environment = {
        XDG_RUNTIME_DIR = "/run";
        PULSE_SERVER = "/run/pulse/native";
        PULSE_COOKIE = "DISABLED";
        CLIENT_NAME = "home-server";
        HOST = "127.0.0.1";
        PORT = "6053";
        ENABLE_ENCRYPTION = "1";
        AUDIO_INPUT_DEVICE = "default";
        AUDIO_OUTPUT_DEVICE = "pulse";
        MUSIC_OUTPUT_DEVICE = "pulse";
        MIC_AUTO_GAIN = "1";
        MIC_NOISE_SUPPRESSION = "2";
      };
      user = "995:995";
      volumes = [
        "/run/pipewire:/run/pipewire"
        "/run/pulse:/run/pulse"
        "/var/lib/server-voice/lva:/app/configuration"
        "/var/lib/server-voice/lva/wakewords:/app/wakewords"
        "/var/lib/server-voice/lva/sounds:/app/sounds/custom"
        "/var/lib/server-voice/lva/local:/app/local"
        "/etc/localtime:/etc/localtime:ro"
      ];
      capabilities = { SYS_NICE = true; };
    };

    systemd.services."docker-linux-voice-assistant" = lib.mkIf cfg.lva.enable {
      after = [ "docker.service" "pipewire.service" "pipewire-pulse.service" ];
      wants = [ "docker.service" "pipewire.service" "pipewire-pulse.service" ];
    };

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

    systemd.services.server-voice-event-handler = {
      description = "Handle voice wake-word events";
      wantedBy = [ "multi-user.target" ];
      after = [ "server-voice-satellite.service" ];
      wants = [ "server-voice-satellite.service" ];
      serviceConfig = {
        ExecStart = "${eventHandler}/bin/server-voice-event-handler";
        Restart = "always";
        User = "server-voice";
        Group = "server-voice";
        SupplementaryGroups = [ "audio" ];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        RuntimeDirectory = "server-voice";
      };
    };

    systemd.services.server-voice-openwakeword.enable = !cfg.lva.enable;
    systemd.services.server-voice-satellite.enable = !cfg.lva.enable;
    systemd.services.server-voice-event-handler.enable = !cfg.lva.enable;

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
