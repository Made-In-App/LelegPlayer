# IPTV All Platform — Guida Setup

## Requisiti

- **Flutter SDK** ≥ 3.19 → https://flutter.dev/docs/get-started/install
- **Dart** ≥ 3.0 (incluso con Flutter)
- **Xcode** 15+ (per iOS/macOS)
- **Android Studio** / Android SDK (per Android/FireTV)

---

## 1. Setup iniziale

```bash
# Clona il progetto
cd "IPTV all platform"

# Genera file Hive (playlist.g.dart)
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 2. Build per piattaforma

### iOS / iPhone
```bash
flutter build ios --release
# Poi apri ios/Runner.xcworkspace in Xcode e fai archive
```

### macOS
```bash
flutter build macos --release
# App in: build/macos/Build/Products/Release/iptv_all_platform.app
```

### Android (Phone / Tablet)
```bash
flutter build apk --release
# APK in: build/app/outputs/flutter-apk/app-release.apk
```

### Amazon Fire TV / Firestick
Fire OS è basato su Android. Stesso APK, con un accorgimento:
1. Abilita "ADB Debugging" nel Fire TV (Impostazioni → Sistema → Opzioni sviluppatore)
2. Connetti via ADB: `adb connect <IP_FIRETV>:5555`
3. Installa: `adb install build/app/outputs/flutter-apk/app-release.apk`

Per navigazione D-pad ottimizzata, il layout adattivo (isTV = true quando width > 1200px) viene attivato automaticamente.

### Samsung Smart TV (Tizen)

Richiede **flutter-tizen** (plugin community):
```bash
# Installa flutter-tizen
git clone https://github.com/flutter-tizen/flutter-tizen.git
export PATH="$PATH:$(pwd)/flutter-tizen/bin"

# Verifica
flutter-tizen doctor

# Build per Tizen
flutter-tizen build tpk --release

# Deploy su TV Samsung (abilita Developer Mode nelle impostazioni TV)
flutter-tizen install --device-id <TV_IP>
```

**Developer Mode TV Samsung:**
1. App → Cerca "12345" → apri il browser delle app
2. Vai su Impostazioni → Attiva Developer Mode
3. Inserisci l'IP del tuo computer

---

## 3. Chromecast

Per il supporto Chromecast aggiungere in `pubspec.yaml`:
```yaml
flutter_cast_framework: ^0.5.0
```

Poi configurare il receiver ID nell'app e usare `CastSession` per inviare lo stream al TV.

---

## 4. Struttura file generati da completare

Dopo `build_runner`, sarà generato:
- `lib/data/models/playlist.g.dart` → adapter Hive

---

## 5. Aggiungere una playlist

1. Avvia l'app
2. Vai su **Playlist** (icona nel menu)
3. Premi **Aggiungi**
4. Scegli tipo:
   - **M3U/M3U8**: incolla l'URL della lista
   - **Xtream Codes**: inserisci server, username, password
5. (Opzionale) aggiungi URL EPG XMLTV per la guida programmi

---

## 6. Catchup / Timeshift

Il catchup funziona automaticamente se:
- Il canale ha `tvg-rec="1"` (M3U) oppure `tv_archive=1` (Xtream)
- Nella EPG grid, i programmi passati con catchup mostrano un'icona ▶ e si possono cliccare
- Lo stream catchup usa il formato timeshift del provider

---

## 7. Roadmap prossimi step

- [ ] Generare `playlist.g.dart` con `build_runner`
- [ ] Aggiungere navigazione D-pad completa per Fire TV / Tizen
- [ ] Implementare Chromecast (flutter_cast_framework)
- [ ] Multi-profilo con PIN
- [ ] Download EPG automatico in background (WorkManager)
- [ ] Test su Samsung Tizen reale

---

## Reference

- `bsogulcan/another-iptv-player` — Flutter IPTV open-source (MIT)
- `flutter-tizen/flutter-tizen` — Flutter per Samsung Tizen
- Xtream Codes API: https://github.com/AndreyPavlenko/Fermata/discussions/434
