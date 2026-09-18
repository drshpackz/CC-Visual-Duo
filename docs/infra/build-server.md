# Build server — Scaleway

Временная машина для сборки Visual Studio Duo (форк VS Code).
Создана 2026-09-18. **Удалить, когда работа закончена** — тарифицируется почасово.

## Инстанс

| | |
|---|---|
| Имя | `vscode-build` |
| ID | `9e9c7b14-e447-410c-9de0-850fd96666b7` |
| Тип | POP2-HC-32C-64G — 32 выделенных vCPU (AMD EPYC), 64 GB RAM |
| Диск | 200 GB SBS NVMe (`/dev/sda1`) |
| IP | `163.172.190.26` |
| Зона | `fr-par-1` |
| Проект / орг | `relay` — `8da982a4-5b38-4f9d-83fe-e77e8c635ca0` |
| ОС | Ubuntu 24.04 LTS |

## Доступ

```bash
ssh -i ~/.ssh/scw-vscode-build root@163.172.190.26
```

- Приватный ключ: `~/.ssh/scw-vscode-build` (на этой машине, не в git).
- В Scaleway IAM ключ зарегистрирован как `vscode-build` (`3ca9cb3f-0150-4e17-9cb1-0b5d8d30ca43`).

## Scaleway CLI

- `scw` установлен в `~/.local/bin/scw` (2.58.3).
- Конфиг и access/secret key: `~/.config/scw/config.yaml`, профиль `default`
  (org/project `8da982a4-…`, регион `fr-par`, зона `fr-par-1`). Не копировать в репо.

```bash
scw instance server list zone=fr-par-1
scw instance server stop  9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1
scw instance server start 9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1 -w
# полное удаление (инстанс + диск + IP) — прекращает списание:
scw instance server terminate 9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1 with-ip=true with-block=true
```

## Стоимость

| Компонент | €/час | €/сутки |
|---|---|---|
| Инстанс | 0.851 | 20.4 |
| Диск 200 GB | ~0.024 | 0.57 |
| IPv4 | 0.004 | 0.10 |
| **Итого** | **~0.88** | **~21** |

Остановленный инстанс не тарифицируется, но диск и IP — да. Дёшево только если удалять после сессии.

## Что стоит на сервере

- Node 24.21 (требование `.nvmrc`), npm 10.9, Python 3.12, gcc 13.3
- Системные libs для native-модулей: `libx11-dev libxkbfile-dev libsecret-1-dev libkrb5-dev`, `fakeroot`, `rpm`
- `fs.inotify.max_user_watches=524288`
- `/root/vscode` — клон с `origin` = `drshpackz/CC-Visual-Duo`, `upstream` = `microsoft/vscode`, `node_modules` установлены

## Замеры

| Операция | Время |
|---|---|
| `git clone --depth=1` | 7 с |
| `npm ci` | ~90 с |
| `npm run compile` (полная) | 35 с (3.5 мин CPU) |
| `gulp vscode-linux-x64` (упаковка) | не замерено, ожидается 3–5 мин |

Использовать `NODE_OPTIONS=--max-old-space-size=8192`.

## Воронка работы

Локальный клон `/root/projects/CC-Visual-Duo` — единственное место правок и git-истории.
Сервер — только вычисления. Всё через `scripts/remote.sh`:

```bash
scripts/remote.sh compile          # rsync изменений (~2 с) + полная компиляция (~35 с)
scripts/remote.sh watch            # инкрементальная сборка
scripts/remote.sh test <pattern>   # unit-тесты
scripts/remote.sh package          # gulp vscode-linux-x64-min
scripts/remote.sh run '<cmd>'      # любая команда в /root/vscode после sync
scripts/remote.sh fetch <remote> [local]   # забрать артефакты
scripts/remote.sh ssh | status | stop | start
```

rsync исключает `.git`, `node_modules`, `out`, `.build`, `.claude`. Коммит и push — отсюда.
