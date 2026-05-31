#!/bin/bash
cd "$(dirname "$0")"

echo "=== LelegPlayer — Git Push ==="
echo ""

rm -f .git/index.lock 2>/dev/null

git config user.email "amicocaroecampus@gmail.com"
git config user.name "Made-In-App"

git add .
git commit -m "fix: playlistsProvider ora StreamProvider reattivo — canali si caricano automaticamente dopo add/toggle/delete playlist" 2>/dev/null || echo "Nessun nuovo commit"

echo ""
git push origin main

echo ""
echo "=== Fatto! Premi Invio per chiudere ==="
read
