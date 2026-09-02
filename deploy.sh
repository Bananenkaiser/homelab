#!/usr/bin/env bash
# Auf dem Raspberry Pi ausführen. Holt den neuesten Stand und fährt alle Stacks
# in diesem Repo hoch. Traefik zuerst.
#
#   ~/homelab/deploy.sh              # alle Stacks
#   ~/homelab/deploy.sh kiwix        # nur einen
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "FEHLER: .env fehlt. Anlegen mit:  cp .env.example .env  und APPDATA setzen." >&2
  exit 1
fi
set -a; . ./.env; set +a          # APPDATA für die compose-Interpolation

git pull --ff-only

docker network inspect traefik-net >/dev/null 2>&1 || docker network create traefik-net

up() {
  local dir="$1"
  [ -f "$dir/docker-compose.yml" ] || return 0
  echo ">> $dir"
  docker compose --env-file .env -f "$dir/docker-compose.yml" up -d
}

if [ $# -gt 0 ]; then
  up "$1"
  exit 0
fi

up traefik
for d in */; do
  d="${d%/}"
  case "$d" in traefik|TEMPLATE) continue ;; esac
  up "$d"
done

docker image prune -f >/dev/null
echo "fertig."
