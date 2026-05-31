# IPTV All Platform — Architettura del Progetto

## Obiettivo

App IPTV ispirata a TiviMate 8K con:
- Supporto liste **M3U/M3U8** e **Xtream Codes API**
- **EPG** (guida elettronica dei programmi, XMLTV)
- **Catchup / Timeshift** (riavvolgimento del passato)
- **Ricerca globale** su canali, film, serie
- **Multi-playlist** (più provider IPTV contemporaneamente)

---

## Piattaforme Target

| Piattaforma | Tecnologia | Note |
|---|---|---|
| **iPhone / iPad** | Flutter iOS | Nativo con AVFoundation |
| **macOS** | Flutter macOS | App desktop nativa |
| **Android Phone/Tablet** | Flutter Android | |
| **Fire TV / Firestick** | Flutter Android (TV) | Fire OS è basato su Android; basta abilitare `android:isGame="false"` e navigazione D-pad |
| **Chromecast** | flutter_cast_framework | Cast dal telefono alla TV |
| **Samsung Smart TV (Tizen)** | flutter-tizen | Plugin community: https://github.com/flutter-tizen/flutter-tizen |

---

## Stack Tecnico

### Framework
- **Flutter 3.x** (Dart) — unica codebase per tutte le piattaforme mobile/desktop
- **flutter-tizen** per Samsung Tizen (build separata, stesso codice Dart)

### State Management
- **Riverpod 2** (`flutter_riverpod`) — provider-based, testabile, compile-safe

### Video Player
- **media_kit** (`media_kit` + `media_kit_video`) — basato su libmpv, supporta HLS/MPEG-TS/DASH, subtitle, track selection, catchup

### Rete & HTTP
- **dio** — HTTP client con interceptor, timeout, retry
- **http** — per chiamate semplici

### Storage
- **Hive** (NoSQL locale, veloce) — playlists, canali, preferiti, cronologia
- **shared_preferences** — impostazioni app

### Parsing
- **xml** — parsing XMLTV per EPG
- Parser M3U custom (incluso nel progetto)

### UI / Navigazione
- **go_router** — navigazione dichiarativa, deep link
- **flutter_staggered_grid_view** — griglia EPG
- Widget personalizzati per navigazione D-pad su TV

### Chromecast
- **flutter_cast_framework** — Google Cast SDK

---

## Struttura Cartelle

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # MaterialApp + Router
│
├── core/
│   ├── constants.dart
│   ├── theme.dart               # Dark theme TV-friendly
│   └── router.dart              # go_router routes
│
├── data/
│   ├── models/
│   │   ├── playlist.dart        # PlaylistSource (M3U | Xtream)
│   │   ├── channel.dart         # Channel (live TV)
│   │   ├── movie.dart           # VodMovie
│   │   ├── series.dart          # VodSeries / Episode
│   │   └── epg_program.dart     # EPGProgram (XMLTV)
│   │
│   ├── parsers/
│   │   ├── m3u_parser.dart      # Parser M3U/M3U8 → List<Channel>
│   │   └── xmltv_parser.dart    # Parser XMLTV → Map<channelId, List<EPGProgram>>
│   │
│   ├── services/
│   │   ├── xtream_service.dart  # Xtream Codes API client
│   │   ├── epg_service.dart     # Scarica + aggiorna EPG
│   │   └── catchup_service.dart # Costruisce URL catchup
│   │
│   └── repositories/
│       ├── playlist_repository.dart
│       ├── channel_repository.dart
│       └── epg_repository.dart
│
├── features/
│   ├── playlists/               # Aggiunta/gestione liste IPTV
│   ├── channels/                # Live TV browser
│   ├── epg/                     # Griglia EPG orizzontale
│   ├── player/                  # Video player + catchup
│   ├── vod/                     # Film e serie
│   ├── search/                  # Ricerca globale
│   └── settings/                # Impostazioni app
│
└── shared/
    ├── widgets/                 # Widget riutilizzabili
    └── utils/                   # Helper functions
```

---

## Architettura Dati

### PlaylistSource
```dart
enum PlaylistType { m3u, xtream }

class PlaylistSource {
  String id;
  String name;
  PlaylistType type;
  // M3U
  String? m3uUrl;
  // Xtream
  String? serverUrl;
  String? username;
  String? password;
  // EPG
  String? epgUrl;          // URL XMLTV
  DateTime? lastSynced;
}
```

### Xtream Codes API
Base URL: `http://SERVER:PORT/player_api.php`

| Endpoint | Parametri | Risposta |
|---|---|---|
| Login & info | `username`, `password` | server info, user info |
| Live streams | `action=get_live_streams` | lista canali |
| Live categories | `action=get_live_categories` | categorie live |
| VOD streams | `action=get_vod_streams` | film |
| Series | `action=get_series` | serie |
| EPG (short) | `action=get_short_epg&stream_id=X` | EPG canale |
| EPG (full) | `action=get_xmltv_url` oppure XML download | EPG completo |

### Catchup
- Formato URL standard: `http://SERVER/STREAM_ID.m3u8?catchup=1&utc=TIMESTAMP&lutc=TIMESTAMP`
- Attributo M3U: `tvg-rec="1"` indica che il catchup è disponibile
- Xtream: `time_start` e `time_end` nei parametri

---

## Flusso EPG

```
Startup
  └─> PlaylistRepository.sync()
        ├─> M3UParser.parse(url) → List<Channel>
        └─> XtreamService.getLiveStreams() → List<Channel>

EPGService.sync()
  ├─> Scarica XMLTV (gzip supportato)
  ├─> XMLTVParser.parse() → Map<channelId, List<EPGProgram>>
  └─> EPGRepository.save()

EPGGrid (UI)
  ├─> Asse X: tempo (scorrimento orizzontale)
  ├─> Asse Y: canali
  └─> Highlight: programma corrente
```

---

## Navigazione TV (D-pad)

Tutte le schermate devono supportare navigazione con:
- **Frecce** (su/giù/sinistra/destra)
- **OK / Seleziona**
- **Back / ESC**
- **Play/Pause** (tasto media)

Usare `Focus` widget + `FocusTraversalGroup` per gestire il focus correttamente.

---

## Roadmap

### Fase 1 — MVP (questo sprint)
- [ ] Setup progetto Flutter multi-piattaforma
- [ ] Aggiunta playlist M3U e Xtream Codes
- [ ] Browser canali live con player HLS
- [ ] EPG base (programma corrente + successivo)
- [ ] Ricerca globale

### Fase 2
- [ ] EPG grid completa (stile TiviMate)
- [ ] Catchup / Timeshift
- [ ] VOD (film e serie)
- [ ] Preferiti e cronologia

### Fase 3
- [ ] Build Samsung Tizen (flutter-tizen)
- [ ] Chromecast support
- [ ] Multi-profilo / parental control
- [ ] Aggiornamento automatico EPG in background

---

## Referenze Open Source

- `bsogulcan/another-iptv-player` — Flutter IPTV player (MIT) con Xtream + M3U, usa media_kit
- `brunocarvalhodearaujo/xtream-codes` — SDK JS per Xtream API (documentazione)
- `flutter-tizen/flutter-tizen` — Flutter per Samsung Tizen
- Xtream Codes API docs: https://github.com/AndreyPavlenko/Fermata/discussions/434
