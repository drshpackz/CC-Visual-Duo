#!/usr/bin/env bash
# Build Visual Studio Duo on this Mac (Apple Silicon).
set -euo pipefail
cd "$(dirname "$0")/.."

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=4096}"
export PATH="$HOME/.local/bin:$PATH"

OUT="../VSCode-darwin-arm64"

case "${1:-}" in
  install)     python3 -m pip install -q --user setuptools 2>/dev/null || true; npm ci ;;
  compile)     time npm run compile ;;
  watch)       npm run watch ;;
  test)        shift; npm run test-node -- "$@" ;;
  package)     time npm run gulp vscode-darwin-arm64-min; ls -d "$OUT"/*.app ;;
  install-app)
    APP=$(ls -d "$OUT"/*.app)
    NAME=$(basename "$APP")
    codesign --force --deep --sign - "$APP"
    rm -rf "/Applications/$NAME"
    cp -R "$APP" /Applications/
    xattr -cr "/Applications/$NAME"
    echo "installed /Applications/$NAME" ;;
  *) echo "usage: $0 install|compile|watch|test [pattern]|package|install-app"; exit 1 ;;
esac
