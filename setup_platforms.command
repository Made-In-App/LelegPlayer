#!/bin/bash
cd "$(dirname "$0")"

echo "=== LelegPlayer — Setup piattaforme Flutter ==="
echo ""

# Aggiunge le cartelle macos/, android/, ios/ al progetto esistente
flutter create --platforms=macos,android,ios --org com.madeinapp .

echo ""
echo "=== Aggiorno dipendenze... ==="
flutter pub get

echo ""
echo "=== Genero adapter Hive (playlist.g.dart)... ==="
flutter pub run build_runner build --delete-conflicting-outputs

echo ""
echo "=== Avvio su macOS... ==="
flutter run -d macos

echo ""
echo "Premi Invio per chiudere"
read
