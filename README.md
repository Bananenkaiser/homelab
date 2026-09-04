# homelab

Lokale Websites auf dem Raspberry Pi (`raspberrypi`, `192.168.178.52`),
erreichbar über `*.lan`. Ein zentraler Reverse Proxy (Traefik) verteilt anhand
der Adresse.

## Der Pi (Ist-Zustand)

- OpenMediaVault, Docker 29, Docker-Daten liegen bereits auf der HDD
  (`Docker Root Dir = $DISK/docker`).
- **Docker 29 hat alte API-Versionen entfernt; Traefik spricht 1.24.** Fix:
  `/etc/systemd/system/docker.service.d/min-api.conf` mit
  `Environment=DOCKER_MIN_API_VERSION=1.24`. Ohne das sieht Traefik keine Container.
- **Pi-hole belegte Port 80.** Admin-Oberfläche jetzt auf
  `http://192.168.178.52:8081/admin` (`webserver.port` in `/etc/pihole/pihole.toml`).
- **Wildcard-DNS:** `etc_dnsmasq_d = true` in `pihole.toml`,
  `/etc/dnsmasq.d/02-lan.conf` = `address=/lan/192.168.178.52`. Jede `*.lan` → Pi.
- 2-TB-btrfs-Platte gemountet unter
  `$DISK = /srv/dev-disk-by-uuid-672d33ef-9522-48ce-a5ea-711cb8119569`
  (~677 GB frei). SD-Karte nur 15 GB – **alle Daten auf die HDD**.
- Apps liegen unter `$DISK/apps/`. `bundesliga_data` ist dort schon geklont
  und läuft per cron (`run-bundesliga.sh`), nicht als Dauer-Container.
- Netz `traefik-net` existiert bereits.

## Was gehört wohin

| Sorte | Beispiel | Ort |
|---|---|---|
| Infrastruktur | Traefik | `traefik/` in diesem Repo |
| Fertige Apps (nur Konfig) | Kiwix (offline-Wikipedia) | eigener Ordner in diesem Repo |
| Selbstgebaute Apps (mit Code) | `bundesliga-web` | **eigenes Repo**, geklont nach `$DISK/apps/` |
| Persistente Daten Dritter | `.zim`, DB-Volumes, Medien | `$APPDATA/<app>/` auf der HDD – **nie im Repo** |

`$APPDATA` wird einmalig in `.env` gesetzt (siehe `.env.example`). Alle
compose-Dateien beziehen ihre Daten-Volumes daraus.

`bundesliga_data` ist die Ausnahme: die cron-Pipeline verwaltet ihre CSVs im
eigenen Repo-Checkout. `bundesliga-web` liest sie aus dem Schwester-Ordner
(`$DISK/apps/bundesliga_data/data`).

## Pi-Layout

```
$DISK/apps/
  homelab/                 <- dieses Repo
    .env                   <- APPDATA=...            (nicht in git)
    traefik/ kiwix/ TEMPLATE/ deploy.sh
  bundesliga-web/          <- eigenes Repo
  bundesliga_data/         <- schon da (cron-Pipeline; CSVs in data/)
$APPDATA/                  <- = $DISK/appdata
  kiwix/*.zim
```

## Einmalige Einrichtung (Pi)

```bash
DISK=/srv/dev-disk-by-uuid-672d33ef-9522-48ce-a5ea-711cb8119569
cd $DISK/apps
git clone https://github.com/Bananenkaiser/homelab.git
git clone https://github.com/Bananenkaiser/bundesliga-web.git

cd homelab
cp .env.example .env                       # APPDATA passt schon
mkdir -p "$(. ./.env; echo "$APPDATA")"/kiwix

docker network inspect traefik-net >/dev/null 2>&1 || docker network create traefik-net
./deploy.sh                                 # Traefik + alle Stacks hoch
```

**Pi-hole-Wildcard** ist schon eingerichtet (siehe „Der Pi" oben) – jede neue
`*.lan`-Adresse löst automatisch auf, kein weiterer Eintrag nötig.

## Alltag

```bash
# lokal am Rechner: ändern, committen, pushen. Dann auf dem Pi:
$DISK/apps/homelab/deploy.sh                 # alles
$DISK/apps/homelab/deploy.sh kiwix           # nur einer
```

Selbstgebaute Apps haben ihr eigenes Update-Skript
(`$DISK/apps/bundesliga-web/deploy/update.sh`).

## Neue fertige App hinzufügen

```bash
cd $DISK/apps/homelab
cp -r TEMPLATE meinedienst
# in meinedienst/docker-compose.yml alle __NAME__ -> meinedienst, image + Port setzen
git add meinedienst && git commit -m "add meinedienst" && git push
# auf dem Pi:
./deploy.sh meinedienst
# http://meinedienst.lan
```

Konvention: **Ordnername = Router-Name = Subdomain**. Immer identisch.

## Neue selbstgebaute App

Eigenes Repo anlegen, `docker-compose.yml` nach dem Muster in `TEMPLATE/`
(mit `build: .` statt `image:`), nach `$DISK/apps/` klonen, eigenes
`deploy/update.sh`.

## Aktive Seiten

| Adresse | Stack | Status |
|---|---|---|
| `traefik.lan` | `homelab/traefik` | **läuft** (v3.5) |
| `jelly.lan` | `homelab/traefik/dynamic/jellyfin.yml` → NAS `192.168.178.59:8096` | Jellyfin auf dem NAS, per File-Provider geproxyt |
| `wiki.lan` | `homelab/kiwix` | noch nicht deployed (braucht `.zim` in `$APPDATA/kiwix`) |
| `tippspiel.lan` | `bundesliga-web` | noch nicht deployed (App wird noch gebaut) |
