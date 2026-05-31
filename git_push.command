#!/bin/bash
cd "$(dirname "$0")"

echo "=== LelegPlayer — Git Push ==="
echo ""

rm -f .git/index.lock 2>/dev/null

git config user.email "amicocaroecampus@gmail.com"
git config user.name "Made-In-App"

git add .
git commit -m "feat: player TV-style con auto-hide, seek bar, +10/-10s, ricarica live, fix back navigation" 2>/dev/null || echo "Nessun nuovo commit"

echo ""
git push origin main

echo ""
echo "=== Fatto! Premi Invio per chiudere ==="
read
