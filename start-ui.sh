#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_DIR="${SCRIPT_DIR}"

get_local_ip() {
  if command -v ip >/dev/null 2>&1; then
    ip -4 addr show scope global | awk '/inet / {sub(/\/.*/, "", $2); if ($2 != "127.0.0.1") {print $2; exit}}'
    return
  fi

  if command -v hostname >/dev/null 2>&1; then
    hostname -I 2>/dev/null | awk '{print $1}'
    return
  fi
}

SERVER_HOST="${SERVER_HOST:-}"
if [ -z "${SERVER_HOST}" ]; then
  SERVER_HOST="$(get_local_ip)"
  echo "自动检测到本机 IP: ${SERVER_HOST}"
else
  echo "使用环境变量 SERVER_HOST: ${SERVER_HOST}"
fi

if [ -z "${SERVER_HOST}" ]; then
  echo "无法自动检测 SERVER_HOST，请先 export SERVER_HOST=你的服务器IP" >&2
  exit 1
fi

UI_PORT="${UI_PORT:-7000}"
STATS_API_PORT="${STATS_API_PORT:-8000}"
CHATBOT_WS_PORT="${CHATBOT_WS_PORT:-18789}"

export SERVER_HOST
export VITE_API_URL="/"
export VITE_API_BASE_URL="/"
export VITE_CHATBOT_URL="ws://${SERVER_HOST}:${CHATBOT_WS_PORT}/"
export VITE_WS_URL="${VITE_CHATBOT_URL}"
export VITE_DEV_STATS_API_TARGET="http://${SERVER_HOST}:${STATS_API_PORT}"

echo "前端访问地址: http://${SERVER_HOST}:${UI_PORT}"

cd "${UI_DIR}"
npm run dev -- --host 0.0.0.0 --port "${UI_PORT}"