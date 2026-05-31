#!/bin/bash
echo "=== Fix Xcode developer tools ==="
echo ""

# Imposta Xcode come developer directory attiva
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Accetta la licenza Xcode (richiede password admin)
sudo xcodebuild -license accept

echo ""
echo "Verifica:"
xcodebuild -version

echo ""
echo "=== Avvio LelegPlayer su macOS ==="
cd "$(dirname "$0")"
flutter run -d macos

echo ""
echo "Premi Invio per chiudere"
read
