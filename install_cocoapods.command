#!/bin/bash
echo "=== Installazione CocoaPods ==="
echo ""

# Installa CocoaPods via Homebrew (preferito)
if command -v brew &>/dev/null; then
  brew install cocoapods
else
  # Fallback via gem
  sudo gem install cocoapods
fi

echo ""
echo "Verifica:"
pod --version

echo ""
echo "=== Avvio LelegPlayer su macOS ==="
cd "$(dirname "$0")"
flutter run -d macos

echo ""
echo "Premi Invio per chiudere"
read
