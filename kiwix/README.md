# kiwix – offline-Wikipedia & Co.

Serviert `.zim`-Dateien (Wikipedia, Wiktionary, Stack Exchange, …) unter `wiki.lan`.

## Inhalte besorgen

`.zim`-Dateien von <https://download.kiwix.org/zim/> herunterladen und nach
`$APPDATA/kiwix/` legen (`$APPDATA` = HDD-Mountpoint aus `~/homelab/.env`).

Beispiele (Stand 2026, Größen ungefähr):

| Datei | Inhalt | Größe |
|---|---|---|
| `wikipedia_de_all_maxi_*.zim` | dt. Wikipedia mit Bildern | ~50 GB |
| `wikipedia_de_all_nopic_*.zim` | dt. Wikipedia ohne Bilder | ~15 GB |
| `wikipedia_de_all_mini_*.zim` | nur Einleitungen | ~3 GB |

```bash
source ~/homelab/.env
mkdir -p "$APPDATA/kiwix" && cd "$APPDATA/kiwix"
wget https://download.kiwix.org/zim/wikipedia/wikipedia_de_all_nopic_2026-XX.zim
```

## Starten

```bash
cd ~/homelab/kiwix && docker compose up -d
# http://wiki.lan
```

Nach dem Hinzufügen weiterer `.zim`-Dateien: `docker compose restart kiwix`.
