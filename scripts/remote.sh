#!/usr/bin/env bash
# Local tree is the source of truth; the Scaleway box does the heavy lifting.
set -euo pipefail

HOST="${VSD_HOST:-root@163.172.190.26}"
KEY="${VSD_KEY:-$HOME/.ssh/scw-vscode-build}"
REMOTE_DIR="${VSD_REMOTE_DIR:-/root/vscode}"
LOCAL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

SSH=(ssh -i "$KEY" -o StrictHostKeyChecking=accept-new "$HOST")
RSYNC_EXCLUDES=(--exclude .git --exclude node_modules --exclude out --exclude .build --exclude '*.vsix' --exclude .claude --exclude .DS_Store)

sync() {
  rsync -rlptDz --delete "${RSYNC_EXCLUDES[@]}" -e "ssh -i $KEY" "$LOCAL_DIR/" "$HOST:$REMOTE_DIR/"
}

remote() {
  "${SSH[@]}" "cd $REMOTE_DIR && export NODE_OPTIONS=--max-old-space-size=8192 && $*"
}

case "${1:-}" in
  sync)     sync ;;
  run)      shift; sync; remote "$@" ;;
  install)  sync; remote "npm ci" ;;
  compile)  sync; remote "time npm run compile" ;;
  watch)    sync; remote "npm run watch" ;;
  test)     shift; sync; remote "npm run test-node -- $*" ;;
  package)  sync; remote "npm run gulp vscode-linux-x64-min && ls -d ../VSCode-linux-x64" ;;
  fetch)    shift; rsync -rlptDz -e "ssh -i $KEY" "$HOST:${1:?remote path}" "${2:-$LOCAL_DIR/.build/}" ;;
  ssh)      "${SSH[@]}" -t "cd $REMOTE_DIR && exec bash -l" ;;
  status)   scw instance server get 9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1 | grep -E '^(Name|State|PublicIP.Address|CommercialType)' ;;
  stop)     scw instance server stop  9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1 ;;
  start)    scw instance server start 9e9c7b14-e447-410c-9de0-850fd96666b7 zone=fr-par-1 -w ;;
  *) echo "usage: $0 sync|run <cmd>|install|compile|watch|test [pattern]|package|fetch <remote> [local]|ssh|status|stop|start"; exit 1 ;;
esac
