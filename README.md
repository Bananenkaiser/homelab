# homelab

Lokale Websites auf dem Raspberry Pi (`192.168.178.52`), erreichbar über
`*.lan`. Ein zentraler Reverse Proxy (Traefik) verteilt anhand der Adresse.

## Was gehört wohin

| Sorte | Beispiel | Ort |
|---|---|---|
| Infrastruktur | Traefik | `traefik/` in diesem Repo |
| Fertige Apps (nur Konfig) | Kiwix (offline-Wikipedia) | eigener Ordner in diesem Repo |
| Selbstgebaute Apps (mit Code) | `bundesliga-web` | **eigenes Repo**, geklont nach `~/apps/` |
| Persistente Daten Dritter | `.zim`-Dateien, DB-Volumes | `/srv/appdata/<app>/` – **nie im Repo** |

`bundesliga_data` ist die Ausnahme: die Pipeline verwaltet ihre CSVs selbst im
eigenen Repo-Checkout. `bundesliga-web` liest sie aus dem Schwester-Ordner
(`~/apps/bundesliga_data/data`).

## Pi-Layout

```
~/homelab/            <- dieses Repo
  traefik/
  kiwix/
  TEMPLATE/           <- Vorlage für neue fertige Apps
  deploy.sh
~/apps/
  bundesliga-web/     <- eigenes Repo
  bundesliga_data/    <- eigenes Repo (Pipeline; CSVs liegen in dessen data/)
/srv/appdata/
  kiwix/*.zim
```

## Einmalige Einrichtung (Pi)

```bash
docker network create traefik-net

mkdir -p ~/homelab && git clone <URL> ~/homelab
mkdir -p ~/apps && cd ~/apps
git clone https://github.com/Bananenkaiser/bundesliga-web.git
git clone https://github.com/Bananenkaiser/bundesliga_data.git

sudo mkdir -p /srv/appdata/kiwix
sudo chown -R "$USER" /srv/appdata

~/homelab/deploy.sh          # Traefik + alle Stacks hoch
```

**Pi-hole:** Local DNS → eine Wildcard `*.lan` → `192.168.178.52`.
Danach löst jede neue `*.lan`-Adresse automatisch auf – kein weiterer Eintrag nötig.

## Alltag

```bash
# Änderung an einem Stack: lokal committen + pushen, dann auf dem Pi:
~/homelab/deploy.sh                 # alles
~/homelab/deploy.sh kiwix           # nur einer
```

Selbstgebaute Apps haben ihr eigenes Update-Skript (`~/apps/bundesliga-web/deploy/update.sh`).

## Neue fertige App hinzufügen

```bash
cd ~/homelab
cp -r TEMPLATE meinedienst
# in meinedienst/docker-compose.yml alle __NAME__ -> meinedienst, image + Port setzen
git add meinedienst && git commit -m "add meinedienst" && git push
# auf dem Pi:
~/homelab/deploy.sh meinedienst
# http://meinedienst.lan
```

Konvention: **Ordnername = Router-Name = Subdomain**. Immer identisch.

## Neue selbstgebaute App

Eigenes Repo anlegen, `docker-compose.yml` nach dem Muster in `TEMPLATE/`
(mit `build: .` statt `image:`), nach `~/apps/` klonen, eigenes `deploy/update.sh`.

## Aktive Seiten

| Adresse | Stack | Zweck |
|---|---|---|
| `traefik.lan` | `homelab/traefik` | Reverse-Proxy-Dashboard |
| `wiki.lan` | `homelab/kiwix` | offline-Wikipedia (`.zim`) |
| `tippspiel.lan` | `~/apps/bundesliga-web` | Bundesliga-Tipps |
