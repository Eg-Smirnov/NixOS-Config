# Рабочее окружение Codex на `home-server`

## Состояние

- Подключение с клиентской машины проверено через существующий alias `home-server`.
- Codex CLI `0.146.0` и tmux `3.6a` установлены в профиле пользователя `agent`.
- Пользователь `agent` состоит только в своей группе `agent`; он не входит в `wheel` или `networkmanager`.
- Домашний каталог: `/persist/home/agent`, владелец `agent:agent`, режим `0700`. Данные сохраняются на разделе `/persist`.
- Интерактивный вход от `server` в `agent`, создание `repos` и `worktrees`, запуск Codex и подключение к tmux проверены владельцем сервера.
- Clone NixOS-Config находится в `~/repos/NixOS-Config`; тестовый worktree — `~/worktrees/NixOS-Config-stage1-smoke`, ветка `codex/stage1-smoke` отслеживает `origin/master`. Владелец подтвердил чистое Git-состояние.
- NixOS-конфигурация собрана, но не активируется из Codex. Применять системную конфигурацию может только администратор.

## Подключение и tmux

Подключитесь существующим способом:

```sh
ssh home-server
```

В интерактивном терминале перейдите в непривилегированную учётную запись и откройте постоянную сессию:

```sh
sudo -iu agent
tmux new -As agent-work
```

Сессия переживает отключение SSH. Чтобы отсоединиться, нажмите `Ctrl-b`, затем `d`. После следующего подключения повторите `sudo -iu agent` и выполните:

```sh
tmux attach -t agent-work
```

Сессия tmux не переживает перезагрузку сервера; файлы в домашнем каталоге сохраняются.

## Каталоги и Git worktrees

Каталоги рабочего пространства находятся в домашнем каталоге `agent`:

```text
~/repos/       основные клоны репозиториев
~/worktrees/   отдельные рабочие деревья задач
```

Проверенный clone и тестовый worktree:

```text
~/repos/NixOS-Config
~/worktrees/NixOS-Config-stage1-smoke  (ветка codex/stage1-smoke → origin/master)
```

Для другого проекта выберите его URL и имя, затем выполните команды от `agent`:

```sh
git clone <repository-url> "$HOME/repos/<project>"
cd "$HOME/repos/<project>"
git branch -r
git worktree add -b codex/<task> "$HOME/worktrees/<project>-<task>" origin/<base-branch>
cd "$HOME/worktrees/<project>-<task>"
codex
```

Замените значения в угловых скобках. В `origin/<base-branch>` укажите существующую удалённую базовую ветку, например `origin/main` или `origin/master`. Workflow clone и создания worktree проверен на публичном NixOS-Config; URL других репозиториев выбирает владелец.

Список рабочих деревьев можно посмотреть так:

```sh
git -C "$HOME/repos/<project>" worktree list
```

Каждая задача должна работать в собственном worktree и ветке. Слияние, push и удаление worktree выполняйте отдельно после проверки изменений.

## Запуск Codex

Запускайте Codex из каталога проекта или worktree:

```sh
cd "$HOME/worktrees/<project>-<task>"
codex
```

При первом запуске пройдите вход в аккаунт в CLI. Состояние авторизации относится к пользователю `agent` и хранится в его домашнем каталоге. Не копируйте в него credentials пользователя `server` и не помещайте API key в Git или shell history.

Для проверки установленной версии:

```sh
codex --version
tmux -V
git --version
```

## Границы доступа

- Codex работает как `agent`, без `sudo`, членства в административных группах и доступа к сокетам Docker/Podman.
- Домашний каталог `server`, его SSH credentials и SOPS age-ключи не предоставлены `agent`.
- Не запускайте от `agent` команды активации NixOS. Проверку конфигурации и системную активацию выполняет администратор отдельно.
- Clone NixOS-Config загружен по HTTPS. Его flake ссылается на private input; у `agent` нет ключа доступа к нему. Не запускайте от `agent` проверку полной flake-конфигурации без отдельного решения администратора.

## Диагностика

- **Не удаётся подключиться:** проверьте, что используется alias `home-server` и что reverse tunnel домашнего сервера работает. Не меняйте настройки alias, SSH или туннеля в рамках диагностики без отдельного согласования.
- **Не удаётся войти в `agent`:** выполняйте `sudo -iu agent` в интерактивном терминале; `sudo` может запросить пароль пользователя `server`.
- **tmux не находит сессию:** убедитесь, что команда выполняется как `agent`; создайте её командой `tmux new -As agent-work`.
- **Codex просит авторизацию:** завершите sign-in flow как `agent`. Не переносите файлы авторизации между учётными записями.
- **Нет проекта:** используйте clone в `~/repos` или создайте новый по разделу Git worktrees; не используйте `/home/server/NixOS-Config` напрямую.
