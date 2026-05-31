#!/bin/bash
cd "$(dirname "$0")"

echo "=== LelegPlayer — Git Setup & Push ==="
echo ""

# Rimuovi eventuali lock rimasti
rm -f .git/index.lock 2>/dev/null

# Configura identità git locale
git config user.email "amicocaroecampus@gmail.com"
git config user.name "Made-In-App"

# Imposta branch main
git branch -m main 2>/dev/null || true

# Aggiungi remote se non esiste
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/Made-In-App/LelegPlayer.git

# Staging e commit
git add .
git commit -m "feat: initial LelegPlayer project scaffold

- Flutter multi-platform IPTV player (iOS, Android, macOS, Fire TV, Tizen)
- M3U/M3U8 + Xtream Codes API support
- EPG grid stile TiviMate (XMLTV), catchup/timeshift
- Global search, VOD, series
- Stack: Flutter + Riverpod + media_kit + Hive + go_router" 2>/dev/null || echo "Nessun nuovo commit (già committato)"

echo ""
echo "Eseguendo push su GitHub..."
git push -u origin main

echo ""
echo "=== Fatto! ==="
echo "Premi Invio per chiudere..."
read
