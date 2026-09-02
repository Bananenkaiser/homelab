# homelab

Lokale Websites auf dem Raspberry Pi (`192.168.178.52`), erreichbar über
`*.lan`. Ein zentraler Reverse Proxy (Traefik) verteilt anhand der Adresse.

## Was gehört wohin

| Sorte | Beispiel | Ort |
|---|---|---|
| Infrastruktur | Traefik | `traefik/` in diesem Repo |
| Fertige Apps (nur Konfig) | Kiwix (offline-Wikipedia) | eigener Ordner in diesem Repo |
| Selbstgebaute Apps (mit Code) | `bundesliga-web` | **eigenes Repo**, geklont nach `~/apps/` |
| Persistente Daten Dritter | `.zim`-Dateien, DB-Volumes, Medien | **auf der 2-TB-Platte**: `$APPDATA/<app>/` – **nie im Repo** |

`$APPDATA` = Mountpoint der externen Festplatte, einmalig gesetzt in `.env`
(siehe `.env.example`). Alle compose-Dateien beziehen ihre Daten-Volumes daraus.
Die SD-Karte trägt nur OS + Repos + Container-Images.

`bundesliga_data` ist die Ausnahme: die Pipeline verwaltet ihre CSVs selbst im
eigenen Repo-Checkout. `bundesliga-web` liest sie aus dem Schwester-Ordner
(`~/apps/bundesliga_data/data`).

## Pi-Layout

```
~/homelab/                 <- dieses Repo (SD-Karte)
  .env                     <- APPDATA=<HDD-Mountpoint>/appdata   (nicht in git)
  traefik/  kiwix/  TEMPLATE/  deploy.sh
~/apps/                    <- eigene Code-Repos (SD-Karte)
  bundesliga-web/
  bundesliga_data/         <- Pipeline; CSVs liegen in dessen data/
<HDD-Mountpoint>/appdata/  <- alle großen/persistenten Daten (2-TB-Platte)
  kiwix/*.zim
```

## Einmalige Einrichtung (Pi)

```bash
docker network create traefik-net

mkdir -p ~/homelab && git clone <URL> ~/homelab
cd ~/homelab
cp .env.example .env
# .env öffnen und APPDATA auf den Mountpoint der Platte setzen,
# z. B.  APPDATA=/mnt/hdd/appdata     (Mountpoint prüfen mit:  df -h  /  lsblk -f)
mkdir -p "$(. ./.env; echo "$APPDATA")"/kiwix

mkdir -p ~/apps && cd ~/apps
git clone https://github.com/Bananenkaiser/bundesliga-web.git
git clone https://github.com/Bananenkaiser/bundesliga_data.git

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

## Optional: Docker-Images auf die HDD

Container-Images landen per Default unter `/var/lib/docker` auf der SD-Karte.
Wenn das eng wird, Docker-Daten auf die Platte verlegen:

```bash
sudo systemctl stop docker
sudo mkdir -p "$APPDATA/docker"
echo '{ "data-root": "'"$APPDATA"'/docker" }' | sudo tee /etc/docker/daemon.json
sudo rsync -aP /var/lib/docker/ "$APPDATA/docker/"
sudo mv /var/lib/docker /var/lib/docker.old && sudo systemctl start docker
# läuft alles -> sudo rm -rf /var/lib/docker.old
```

## Aktive Seiten

| Adresse | Stack | Zweck |
|---|---|---|
| `traefik.lan` | `homelab/traefik` | Reverse-Proxy-Dashboard |
| `wiki.lan` | `homelab/kiwix` | offline-Wikipedia (`.zim`) |
| `tippspiel.lan` | `~/apps/bundesliga-web` | Bundesliga-Tipps |
