#!/bin/bash
cd "$(dirname "$0")"

echo "=== LelegPlayer — Git Push ==="
echo ""

rm -f .git/index.lock 2>/dev/null

git config user.email "amicocaroecampus@gmail.com"
git config user.name "Made-In-App"

git add .
git commit -m "feat: EPG auto-sync, D-pad TV nav, catchup, preferiti, cronologia, serie/episodi

- EpgSyncService: sync XMLTV automatico all'avvio con cache 12h
- CatchupService: URL builder per tutti i formati (Xtream timeshift, M3U append/utc)
- FavoritesService: preferiti e cronologia visione persistenti (Hive)
- TvFocusable widget: navigazione D-pad con highlight focus per Fire TV / Tizen
- ChannelsScreen: tab Tutti / Preferiti / Recenti, EPG inline con progress bar
- SeriesDetailScreen: stagioni, episodi, copertina, riproduzione per Xtream
- Router aggiornato con rotta /series
- main.dart: apertura di tutti i box Hive necessari" 2>/dev/null || echo "Nessun nuovo commit"

echo ""
git push origin main

echo ""
echo "=== Fatto! Premi Invio per chiudere ==="
read
