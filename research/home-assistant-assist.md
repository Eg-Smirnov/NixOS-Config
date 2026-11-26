# Исследование: Home Assistant Assist и Linux Voice Assistant на NixOS

Дата исследования: 2026-11-26. Исследованы актуальные `main`-ветки официальных репозиториев без установки, активации или изменения NixOS-сервисов.

## 1. Краткое резюме

**Linux Voice Assistant (LVA)** — это не самостоятельный «мозг», а Linux-сателлит для Home Assistant. Он захватывает звук, локально выполняет wake-word/stop-word detection, опционально применяет WebRTC AGC/noise suppression и передаёт голосовой pipeline в Home Assistant по ESPHome API. Завершение речи определяется не локальным VAD LVA, а событиями Assist Pipeline от Home Assistant.

**Home Assistant Assist** уже разделяет pipeline на wake word, STT, conversation agent и TTS. Wyoming является штатным способом подключать локальные Whisper/Piper/openWakeWord-сервисы, а ESPHome API — способом подключать внешние голосовые сателлиты, включая LVA.

Для нашего сервера наиболее рационален **гибридный путь**: оставить текущий собственный backend и STT/TTS, а из LVA заимствовать/рассмотреть его аудиоконвейер и улучшения обработки звука. Полный переход на Assist имеет смысл для Home Assistant-команд, но не должен становиться обязательным «мозгом» будущей мультиагентной системы.

## 2. Источники и методика

Основные источники:

- [OHF-Voice/linux-voice-assistant](https://github.com/OHF-Voice/linux-voice-assistant)
- [LVA README](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/README.md)
- [LVA audio pipeline](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/audio_pipeline.md)
- [LVA installation](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install.md)
- [LVA application installation](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md)
- [LVA AEC documentation](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/enabling_aec.md)
- [LVA communication](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/communication.md)
- [LVA source: `__main__.py`](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/__main__.py)
- [LVA source: `satellite.py`](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/satellite.py)
- [LVA source: `webrtc.py`](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/webrtc.py)
- [LVA source: `wake_word_detection.py`](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/wake_word_detection.py)
- [LVA releases](https://github.com/OHF-Voice/linux-voice-assistant/releases)
- [Home Assistant voice control](https://www.home-assistant.io/voice_control/)
- [Home Assistant Assist pipelines](https://www.home-assistant.io/voice_control/voice_remote_local_assistant/)
- [Home Assistant Wyoming integration](https://www.home-assistant.io/integrations/wyoming/)
- [Home Assistant core Assist Pipeline](https://github.com/home-assistant/core/tree/main/homeassistant/components/assist_pipeline)
- [Home Assistant core conversation agents](https://github.com/home-assistant/core/tree/main/homeassistant/components/conversation)
- [Home Assistant core Wyoming integration](https://github.com/home-assistant/core/tree/main/homeassistant/components/wyoming)
- [Home Assistant Whisper integration](https://www.home-assistant.io/integrations/whisper/)
- [Home Assistant Piper integration](https://www.home-assistant.io/integrations/piper/)
- [Home Assistant openWakeWord integration](https://www.home-assistant.io/integrations/openwakeword/)

Репозитории были прочитаны локально в `/tmp` на момент исследования. Точные commit SHA не фиксировались, поэтому ссылки на `main` следует воспринимать как ссылки на актуальную документацию, а при реализации — закрепить версии.

## 3. Что реально делает Linux Voice Assistant

### 3.1 Архитектура

LVA — Python-приложение с двумя способами запуска:

- Docker Compose — рекомендуемый upstream-путь: [docker-compose.yml](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docker-compose.yml), [Dockerfile](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/Dockerfile);
- bare metal/systemd — описан в [install_application.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#b-bare-metal).

По умолчанию LVA связывается с Home Assistant через ESPHome API и автоматически обнаруживается через mDNS/zeroconf. API-порт по документации — `6053`; при включённом шифровании используется ключ из `ENCRYPTION_KEY_FILE` ([communication.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/communication.md), [install_application.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#connecting-to-home-assistant)).

Важное ограничение: LVA не предоставляет в upstream-документации универсальный plugin API для произвольного внешнего «мозга». Его основной контракт — Home Assistant Voice Assistant API. События pipeline и TTS маршрутизируются через HA, а не в произвольный backend.

### 3.2 Аудиопоток

Фактическая последовательность описана в [docs/audio_pipeline.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/audio_pipeline.md):

```text
soundcard / PulseAudio / PipeWire
  → 16 kHz float32
  → software mic volume
  → optional WebRTC AGC + noise suppression
  → local wake/stop word detection
  → VoiceAssistantRequest(start=True)
  → audio to Home Assistant
  → HA STT_VAD_END/STT_END
  → stop streaming
```

Ключевой факт: **LVA не имеет собственного VAD, который завершает фразу**. После wake word он передаёт аудио, пока Home Assistant не пришлёт `STT_VAD_END` или `STT_END` ([audio_pipeline.md, “Who decides when streaming stops”](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/audio_pipeline.md#who-decides-when-streaming-stops-vad)). Это принципиально отличается от нашего текущего фиксированного 5-секундного окна, но требует работающего HA pipeline.

### 3.3 Wake word

Код поддерживает MicroWakeWord и openWakeWord; активны до двух wake-word slots, для каждого есть порог чувствительности. Модели могут быть внутренними, скачанными или custom ([wake_word_detection.py](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/wake_word_detection.py), [install_application.md#custom-wake-word](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#custom-wake-word)).

Есть refractory period: повторные обнаружения можно блокировать в течение заданного времени ([behavior.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/behavior.md)). Это непосредственно решает часть наблюдавшейся у нас проблемы с накоплением повторных wake-word.

LVA также поддерживает stop word, но он является отдельной моделью и активируется в определённых состояниях pipeline; это не замена общему VAD.

### 3.4 Шумоподавление, AGC и AEC

WebRTC processing реализован в `webrtc.py` и подключается опционально через `webrtc-noise-gain`:

- AGC — уровень `MIC_AUTO_GAIN`/Mic Gain;
- noise suppression — уровень `MIC_NOISE_SUPPRESSION` от 0 до 4;
- обработка выполняется на 10-ms frames и только для канала микрофона ([webrtc.py](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/linux_voice_assistant/webrtc.py), [audio_pipeline.md#stages](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/audio_pipeline.md#stages)).

Это подтверждённая обработка, но она отключена по умолчанию. `MIC_VOLUME` — только программное ослабление, а не полноценный gain.

AEC upstream не является универсальным встроенным full-duplex echo canceller. Документация предлагает системный PulseAudio/PipeWire echo cancellation: [enabling_aec.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/enabling_aec.md). Кроме того, LVA может захватывать два канала, где второй — reference signal для аппаратного/системного AEC; он не передаётся как обычное пользовательское аудио ([audio_pipeline.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/audio_pipeline.md#3-optional-webrtc-processing-channel-0-only)).

Следствие для телевизора: AGC/NS могут улучшить разборчивость, но сами по себе не устраняют речь телевизора. Для реального сценария «команда поверх TV» потребуется AEC/reference signal, ducking телевизора или физически лучшее расположение микрофона. Документация подтверждает механизмы, но не доказывает качество на нашем конкретном ALSA-устройстве.

### 3.5 Динамики и ducking

LVA умеет проигрывать wake/processing/end sounds и управлять mpv-выходом. В коде `satellite.py` есть режим ducking для музыки, а параметры `MPV_PLAYER_DUCK_MODE`, `AUDIO_OUTPUT_DEVICE` и `MUSIC_OUTPUT_DEVICE` описаны в [install_application.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#environment-variables-reference).

Это не равнозначно универсальному приглушению любого телевизионного ALSA/PipeWire-потока. Для TV, который не воспроизводится через контролируемый LVA/mpv output, потребуется отдельная интеграция/маршрутизация.

## 4. Совместимость с NixOS

### Подтверждённые плюсы

- Есть headless-сценарий: upstream прямо описывает bare-metal systemd unit без графической сессии ([install_application.md#b-bare-metal](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#b-bare-metal)).
- Есть Docker-образ для amd64, aarch64 и arm/v7 ([install_application.md#docker-image-tags](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#docker-image-tags)).
- Можно запускать под существующим `server-voice`, если дать пользователю доступ к audio/PipeWire или ALSA.
- Интерфейс к Home Assistant сетевой, поэтому STT/TTS могут оставаться отдельными Wyoming-сервисами.

### Риски упаковки

Upstream ориентирован на Debian/Pi и Docker, а не на NixOS. Bare-metal инструкция использует `apt`, PulseAudio/PipeWire и clone/setup. Dockerfile устанавливает native/runtime dependencies: ALSA tools, PipeWire/Pulse compatibility, libmpv, NumPy/cffi и WebRTC dependency ([Dockerfile](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/Dockerfile)).

Для Nix потребуется отдельный derivation/overlay или FHS/container strategy. Особые зоны риска:

- `soundcard`, NumPy/cffi и `webrtc-noise-gain` с native wheels/builds;
- `libmpv` и audio server libraries;
- openWakeWord/TFLite native library;
- PipeWire/PulseAudio socket environment;
- wake-word model directories and writable preferences;
- mDNS/zeroconf access;
- optional encryption key storage.

Docker устраняет часть Python packaging work, но добавляет Docker daemon, device/socket passthrough, user/group mapping и отдельную модель хранения. В NixOS это не автоматически проще текущего Wyoming набора.

### Доступ и безопасность

LVA может работать без root и использовать отдельного пользователя. Upstream рекомендует запускать PipeWire и LVA под одним пользователем либо добавить пользователя в `audio` ([install_application.md](https://github.com/OHF-Voice/linux-voice-assistant/blob/main/docs/install_application.md#b-bare-metal)). Для нас это совместимо с `server-voice`, но текущая sandbox-политика должна быть проверена отдельно.

Соединение с HA может быть локальным и зашифрованным ключом. Без HA LVA не имеет полноценного режима обработки команд: wake detection может работать, но основной pipeline и ответы завязаны на HA.

## 5. Home Assistant Assist

### 5.1 Pipeline

Assist Pipeline в HA разделяет этапы wake word, STT, intent/conversation и TTS. Официальная документация: [Voice assistants](https://www.home-assistant.io/voice_control/) и [local voice assistant](https://www.home-assistant.io/voice_control/voice_remote_local_assistant/). В core соответствующий runtime находится в [assist_pipeline](https://github.com/home-assistant/core/tree/main/homeassistant/components/assist_pipeline), включая `run.py`, `pipeline.py`, `models.py` и websocket API.

Встроенный Home Assistant Conversation Agent — только один возможный agent. В core есть общий conversation manager и отдельные интеграции agents, например LLM integrations ([conversation component](https://github.com/home-assistant/core/tree/main/homeassistant/components/conversation)). Поэтому HA pipeline можно использовать с локальным STT/TTS и разными conversation agents, но pipeline API всё равно принадлежит HA.

### 5.2 Wyoming

[Wyoming integration](https://www.home-assistant.io/integrations/wyoming/) подключает внешние сервисы STT, TTS, wake word и intent по Wyoming protocol. Официальные интеграции включают Whisper, Piper и openWakeWord:

- [Whisper](https://www.home-assistant.io/integrations/whisper/)
- [Piper](https://www.home-assistant.io/integrations/piper/)
- [openWakeWord](https://www.home-assistant.io/integrations/openwakeword/)

Это позволяет сохранить наши локальные faster-whisper/Piper модели как отдельные сервисы, если они будут доступны в совместимом Wyoming-режиме. Наличие русского STT/TTS не означает автоматически наличие хорошего русского Conversation Agent: распознавание, генерация ответа и выполнение Home Assistant intents — разные слои.

### 5.3 Сателлиты

LVA подключается к Home Assistant как внешний Assist satellite через ESPHome API. HA отправляет pipeline events обратно сателлиту, включая STT/VAD/TTS lifecycle. Это объясняет, почему LVA не нуждается в собственном фиксированном timeout: HA должен определить конец речи.

В текущем локальном прототипе Wyoming satellite используется только как транспорт между openWakeWord и нашим event-handler. Подключение LVA вместо него означало бы переход на другой протокол и центральную зависимость от HA.

### 5.4 Русский язык и собственные сценарии

Whisper и Piper технически поддерживают русский при наличии подходящих моделей. openWakeWord `hey_jarvis` также не зависит от русского языка фразы команды. Assist может принимать русскую транскрипцию, но качество intent/entity extraction зависит от языка конкретного conversation agent и поддерживаемых HA intents.

Русские allowlist-сценарии можно реализовать:

1. в собственном backend до HA;
2. как HA intents/conversation sentences;
3. через custom conversation agent/integration.

Первый вариант лучше соответствует требованию не делать HA главным мозгом.

## 6. Два архитектурных варианта

### Вариант 1: Home Assistant как центральный компонент

```text
LVA satellite
  → ESPHome Voice Assistant API
  → HA Assist Pipeline
      → Wyoming STT (Whisper)
      → Conversation Agent
      → Wyoming TTS (Piper)
      → HA automation/scripts
```

**Плюсы:** готовый VAD lifecycle, wake-word refractory/state management, UI выбора pipeline, Home Assistant intents, готовые Wyoming integrations, меньше собственного протокола.

**Минусы:** HA становится обязательным backend; дополнительная упаковка HA/LVA; собственные мультиагентные сценарии придётся подключать как conversation agent или обходным API; отладка распределённого pipeline сложнее.

### Вариант 2: HA как инфраструктурный слой

```text
LVA/Wyoming satellite
  → собственный voice gateway
      → локальный STT
      → нормализация/allowlist
      → собственный multi-agent backend
      → при необходимости HA API/Wyoming TTS
```

**Плюсы:** сохраняется независимый мозг, строгая allowlist и локальные политики; HA используется только для устройств/состояний; можно постепенно добавлять агентов.

**Минусы:** LVA напрямую не даёт универсальный backend plugin contract; придётся поддерживать собственный gateway или использовать Wyoming/ESPHome протокол как транспорт; VAD, session state, cancellation, TTS playback и recovery остаются нашей ответственностью.

Практически второй вариант реалистичен **без переписывания LVA**, если собственный backend будет говорить с LVA через ESPHome Voice Assistant API либо если LVA оставить только как reference implementation. Но это уже отдельная реализация server-side protocol; upstream-документация LVA рассчитана на HA, а не на arbitrary server.

## 7. Сравнение с текущим прототипом

| Возможность | Наш прототип | Linux Voice Assistant |
|---|---|---|
| Wake word | openWakeWord Wyoming, `hey_jarvis` | openWakeWord + MicroWakeWord, до 2 slots, thresholds |
| VAD/конец фразы | Нет, фиксированные 5 секунд | Сам LVA VAD не выполняет; HA присылает STT_VAD_END/STT_END |
| STT | faster-whisper напрямую | Через HA pipeline; Wyoming Whisper возможен |
| TTS | Piper напрямую | Через HA pipeline; Wyoming Piper возможен |
| Noise suppression | Нет | Optional WebRTC NS 0–4 |
| AGC | Нет | Optional WebRTC AGC |
| Echo cancellation | Нет | Системный PulseAudio/PipeWire AEC или hardware reference; не гарантирован встроенный software AEC |
| Headless | Да, systemd | Да, systemd или Docker |
| systemd | Нативная NixOS декларация | Upstream bare-metal unit; Nix derivation потребуется |
| Русский STT/TTS | Проверено практически | Совместимо через HA Wyoming, качество pipeline зависит от agent |
| Собственные сценарии | Прямой Python allowlist | HA intents/automations или custom agent; arbitrary backend не основной путь |
| Внешний backend | Уже есть | Через HA/протокол; не готовый generic plugin |
| Повторные wake word | Сейчас могут накапливаться | Есть refractory/pipeline gating |
| TV ducking | Не реализовано | mpv/music ducking; не универсальное TV ducking |

## 8. Что можно оставить без изменений

- `server-voice` и принцип минимальных привилегий;
- существующие модели faster-whisper и Piper;
- ALSA device discovery и проверенные `plughw:1,0` как baseline;
- ночной sleep policy;
- собственную нормализацию русских команд и allowlist;
- тестовый сценарий 440 Hz;
- Home Assistant как будущую интеграцию устройств, но не как обязательный conversation brain.

Наиболее полезно заимствовать не весь LVA, а идеи/механизмы:

- refractory/pipeline gating;
- реальный lifecycle окончания речи через VAD;
- WebRTC AGC/noise suppression;
- optional AEC/reference audio;
- controlled ducking и feedback sounds.

## 9. Ограничения и риски

1. **Аудиокачество не доказано на нашем железе.** Документация описывает WebRTC/AEC knobs, но не даёт результата для нашего микрофона и телевизора; потребуется отдельный тест.
2. **LVA upstream не ориентирован на NixOS.** Docker или собственный derivation потребуют работы с native dependencies и audio sockets.
3. **HA central mode увеличивает blast radius.** При недоступности HA LVA не получает обычный Assist pipeline.
4. **Русский Conversation Agent — отдельный риск.** Русский Whisper transcript не гарантирует корректные HA intents или русские ответы.
5. **AEC и TV.** Reference channel полезен только при наличии соответствующего аудиосигнала/маршрута; простой одно-канальный ALSA capture проблему телевизионной речи не решает.
6. **Протокол и версии.** LVA, ESPHome API, HA core и Wyoming должны быть совместимы; upstream main не заменяет pinning.
7. **Аудиозаписи.** LVA не требует постоянного хранения командного audio, но debug recordings/logging и preferences/encryption key нужно явно контролировать в sandbox.
8. **Сеть.** ESPHome API обычно локален, но его discovery и encryption нужно ограничить локальной сетью/firewall; это не проверялось изменением системы.

## 10. Оценка стоимости миграции

| Вариант | Сложность | Изменения NixOS | Новые сервисы | Зависимость от HA | Оценка |
|---|---:|---:|---:|---:|---|
| Оставить прототип и улучшить VAD/normalization | Низкая–средняя | Малые | Нет | Нет | Лучший краткосрочный путь |
| LVA как satellite, наши STT/TTS/backend | Средняя–высокая | Derivation + protocol adapter | LVA и gateway | Низкая/косвенная | Возможен, но generic backend не upstream use case |
| LVA + полноценный HA Assist | Средняя | LVA packaging + HA deployment | HA, LVA, Wyoming | Высокая | Быстрый путь к HA-устройствам |
| Свой satellite/audio frontend + HA infrastructure | Средняя | Улучшение текущих сервисов | Wyoming/HA по необходимости | Средняя | Лучше сохраняет контроль |
| LVA audio stack частично портировать в текущий модуль | Средняя | Python native deps | Нет обязательных | Нет | Наиболее практично для качества звука |

## 11. Рекомендация

**Не делать полный переход на LVA + Home Assistant Assist прямо сейчас.** Он хорошо решает задачу готового Home Assistant satellite и даёт нам полезные решения для refractory, pipeline state, AGC/NS и AEC-интеграции, но не является готовым независимым backend для мультиагентного ассистента и плохо совпадает с желанием не делать HA обязательным мозгом.

Рекомендуемый порядок:

1. Оставить рабочий NixOS-прототип и заменить фиксированные 5 секунд на локальный VAD/корректный end-of-speech механизм.
2. Добавить refractory/pipeline gating и нормализацию (`тон`, `Тон!`, `тона`), не меняя STT/TTS модели.
3. Отдельно исследовать/протестировать WebRTC NS/AGC и системный PipeWire/PulseAudio AEC на реальном сценарии с телевизором.
4. Поднять Home Assistant Assist только как отдельный экспериментальный infrastructure layer, подключив существующие Whisper/Piper через Wyoming.
5. Если HA-команды окажутся удобнее собственного allowlist, подключить их как один backend/agent, сохранив собственный gateway и возможность обходить HA.
6. Рассматривать LVA как reference или optional satellite после фиксации Nix-пакетирования и протокольного контракта, а не как обязательную замену текущему pipeline.

Итог: **продолжать собственную реализацию, заимствуя проверенные идеи LVA и используя Home Assistant как опциональный слой интеграций.** Полный HA Assist следует внедрять только после отдельного теста русского conversation layer, задержки, VAD и поведения при телевизионном фоне.

## 12. Что осталось проверить практически

- Реальную задержку HA VAD на нашем CPU и микрофоне.
- Качество WebRTC AGC/NS при русской речи и телевизоре.
- Реальный AEC path с PipeWire/PulseAudio и доступным reference audio.
- Полноценную совместимость Nix package/overlay для LVA и native dependencies.
- Русские Assist intents и custom conversation agent.
- Поведение при suspend/resume и недоступности HA.
- Сетевую изоляцию/шифрование ESPHome API в целевой NixOS firewall policy.

Практические тесты намеренно не выполнялись: задача ограничивала исследование и запрещала установку, активацию, запуск новых сервисов и загрузку моделей.
