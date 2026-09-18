# CLAUDE.md — Visual Studio Duo

Форк `microsoft/vscode` → `drshpackz/CC-Visual-Duo`. Цель: собственная сборка VS Code
под свои конфигурации, устанавливаемая на MacBook владельца.

## Машина

Основная и единственная среда — **MacBook владельца** (`macbook-arina`, Apple M1, 8 ядер,
8 GB RAM, macOS 26, arm64). Это одновременно место правок, сборки и установки.
Tailscale-адрес `100.70.106.53`, пользователь `arinasuvorova`; вход по ключу
(`ssh arinasuvorova@100.70.106.53`). Рабочая папка: `~/Projects/CC-Visual-Duo`.

Ubuntu-сервер `server-maga1` (`100.111.168.45`) — посредник не нужен; там лежит копия
клона в `/root/projects/CC-Visual-Duo`, используй её только для git/доков, не для сборки.

Scaleway Linux-инстанс, на котором делались первые замеры, **удалён 2026-09-18**.
История и цены — `docs/infra/build-server.md`. Mac-инстансы Scaleway (`scw apple-silicon`)
на 2026-09-18 везде `no_stock`; если появятся M4-M (32 GB, ~5 €/сутки, min 24 ч) — это
единственный смысл снова арендовать.

## Тулчейн на Маке

- Node **24** через nvm (`~/.nvm`, подключается в `~/.zprofile`; в неинтерактивном ssh
  делай `export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"`). В системе есть чужой
  Node 20 — не он.
- `~/.local/bin`: `scw` 2.62 (профиль `default`, проект `relay`, конфиг
  `~/.config/scw/config.yaml`, не в git), `gh` 2.101 (аккаунт drshpackz), Claude Code.
- Xcode Command Line Tools, Python 3.9 (+ setuptools для node-gyp), git 2.50. Homebrew нет.
- `git-lfs` не установлен, а глобальный LFS-фильтр был — удалён; не возвращать.

## Сборка

```bash
scripts/build.sh install   # npm ci (~2 мин на M1)
scripts/build.sh compile   # npm run compile
scripts/build.sh watch
scripts/build.sh test [pattern]
scripts/build.sh package   # gulp vscode-darwin-arm64-min → ../VSCode-darwin-arm64/*.app
scripts/build.sh install-app   # ad-hoc codesign + копия в /Applications + xattr -cr
```

`NODE_OPTIONS=--max-old-space-size=4096` — 8 GB RAM, больше не давать.
Нет Apple Developer ID → приложение подписывается ad-hoc, карантин снимается `xattr -cr`.
Для раздачи другим понадобится Developer ID (99 $/год) + notarization — тогда в
`.github/workflows/build-macos.yml` добавить подпись через Secrets.

## GitHub Actions

`.github/workflows/build-macos.yml` — сборка на `macos-14` (M1, 3 ядра, 7 GB — медленнее
ноутбука), артефакт `*-darwin-arm64.zip`, Release при теге `v*`. Первый прогон
(`run 35361643446`) **упал на упаковке**: `prepareBuiltInCopilotRipgrepShim` не нашёл
`extensions/copilot/node_modules/@github/copilot/sdk` внутри `.app`. Upstream встраивает
Copilot как built-in extension; нам он не нужен — решить при первой локальной упаковке
(вырезать built-in copilot из `build/gulpfile.vscode.ts` / `product.json`), потом чинить CI.

## Git

- `origin` = `drshpackz/CC-Visual-Duo`, `upstream` = `microsoft/vscode` (main `9b46b4eb`,
  2026-09-18). Conventional commits, маленькие атомарные коммиты, никаких секретов.
- `.gitignore` upstream игнорирует `.claude/` — скилл `.claude/skills/commando/` лежит
  локально на каждой машине, переносить вручную.
- Синхронизировать с upstream: `git fetch upstream && git rebase upstream/main` (или merge —
  решить, когда накопятся свои правки).

## Что своё (пока ничего)

Кастомизации ещё не начаты. Первые кандидаты: `product.json` (`nameLong`, `nameShort`,
`applicationName`, `dataFolderName`, `darwinBundleIdentifier`, иконки в
`resources/darwin/`), дефолтные настройки, встроенные расширения, удаление built-in Copilot.
