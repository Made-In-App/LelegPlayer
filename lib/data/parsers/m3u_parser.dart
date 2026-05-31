import '../models/channel.dart';

/// Parser per file M3U/M3U8 IPTV
class M3UParser {
  static final _extinfRegex = RegExp(r'#EXTINF:(-?\d+)(.*),(.+)');
  static final _attrRegex = RegExp(r'([\w-]+)="([^"]*)"');
  static final _catchupRegex = RegExp(r'catchup="([^"]*)"');
  static final _catchupDaysRegex = RegExp(r'catchup-days="(\d+)"');

  /// Parsa una stringa M3U e restituisce la lista dei canali
  static List<Channel> parse(String content, {String? playlistId}) {
    final channels = <Channel>[];
    final lines = content.split('\n').map((l) => l.trim()).toList();

    String? currentName;
    Map<String, String> currentAttrs = {};
    bool hasCatchup = false;
    int? catchupDays;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Reset
        currentAttrs = {};
        hasCatchup = false;
        catchupDays = null;

        final match = _extinfRegex.firstMatch(line);
        if (match != null) {
          currentName = match.group(3)?.trim();
          final attrString = match.group(2) ?? '';

          // Estrai tutti gli attributi
          for (final attr in _attrRegex.allMatches(attrString)) {
            currentAttrs[attr.group(1)!] = attr.group(2)!;
          }

          // Catchup
          final catchupMatch = _catchupRegex.firstMatch(attrString);
          if (catchupMatch != null) {
            final catchupVal = catchupMatch.group(1);
            hasCatchup = catchupVal == '1' ||
                catchupVal == 'default' ||
                catchupVal == 'append';
          }

          final daysMatch = _catchupDaysRegex.firstMatch(attrString);
          if (daysMatch != null) {
            catchupDays = int.tryParse(daysMatch.group(1)!);
          }
        }
      } else if (!line.startsWith('#') && line.isNotEmpty && currentName != null) {
        // URL stream
        final id = currentAttrs['tvg-id'] ??
            currentAttrs['tvg-name'] ??
            currentName;

        channels.add(Channel(
          id: id,
          name: currentAttrs['tvg-name'] ?? currentName,
          logo: currentAttrs['tvg-logo'],
          streamUrl: line,
          group: currentAttrs['group-title'],
          epgId: currentAttrs['tvg-id'],
          hasCatchup: hasCatchup,
          catchupDays: catchupDays,
          playlistId: playlistId,
        ));

        currentName = null;
        currentAttrs = {};
      }
    }

    return channels;
  }

  /// Raggruppa i canali per categoria
  static Map<String, List<Channel>> groupByCategory(List<Channel> channels) {
    final map = <String, List<Channel>>{};
    for (final ch in channels) {
      final group = ch.group ?? 'Senza categoria';
      map.putIfAbsent(group, () => []).add(ch);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }
}
