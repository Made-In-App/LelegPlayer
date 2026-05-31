import '../models/channel.dart';
import '../models/epg_program.dart';
import '../models/playlist.dart';

/// Costruisce l'URL di catchup per tutti i formati supportati dai provider IPTV
class CatchupService {
  /// Restituisce l'URL catchup per un programma passato, o null se non disponibile
  static String? buildUrl({
    required Channel channel,
    required EPGProgram program,
    required PlaylistSource playlist,
  }) {
    if (!channel.hasCatchup) return null;
    if (!program.isPast && !program.isNow) return null;

    final streamUrl = channel.streamUrl;
    final start = program.start;
    final end = program.end;

    // ── Xtream Codes timeshift ───────────────────────────────
    if (playlist.type == PlaylistType.xtream) {
      return _buildXtreamCatchup(playlist, channel, start, end);
    }

    // ── M3U: rileva il formato catchup dall'URL ──────────────
    return _buildM3uCatchup(streamUrl, start, end);
  }

  // Xtream: http://server/timeshift/user/pass/duration/start/stream.ts
  static String _buildXtreamCatchup(
    PlaylistSource playlist,
    Channel channel,
    DateTime start,
    DateTime end,
  ) {
    final server = playlist.serverUrl!;
    final user = playlist.username!;
    final pass = playlist.password!;
    final duration = end.difference(start).inMinutes;
    final startFmt = _xtreamDateFormat(start);
    // Estrai stream ID dall'URL
    final streamId = _extractStreamId(channel.streamUrl);
    return '$server/timeshift/$user/$pass/$duration/$startFmt/$streamId.ts';
  }

  // M3U: supporta i vari formati dei provider
  static String? _buildM3uCatchup(String streamUrl, DateTime start, DateTime end) {
    final utcStart = start.millisecondsSinceEpoch ~/ 1000;
    final utcEnd = end.millisecondsSinceEpoch ~/ 1000;
    final duration = end.difference(start).inMinutes;

    // Formato 1: {utc} e {lutc} placeholder nell'URL
    if (streamUrl.contains('{utc}') || streamUrl.contains('{lutc}')) {
      return streamUrl
          .replaceAll('{utc}', utcStart.toString())
          .replaceAll('{lutc}', utcEnd.toString())
          .replaceAll('{duration}', duration.toString());
    }

    // Formato 2: ?utc=X&lutc=Y (append)
    final uri = Uri.tryParse(streamUrl);
    if (uri == null) return null;

    // Formato 3: URL con catchup-source nei parametri
    if (uri.queryParameters.containsKey('utc')) {
      final params = Map<String, String>.from(uri.queryParameters)
        ..['utc'] = utcStart.toString()
        ..['lutc'] = utcEnd.toString();
      return uri.replace(queryParameters: params).toString();
    }

    // Formato 4: aggiungi parametri catchup standard
    final params = Map<String, String>.from(uri.queryParameters)
      ..['catchup'] = '1'
      ..['utc'] = utcStart.toString()
      ..['lutc'] = utcEnd.toString()
      ..['duration'] = duration.toString();
    return uri.replace(queryParameters: params).toString();
  }

  // Formato data Xtream: YYYY-MM-DD_HH-MM-SS
  static String _xtreamDateFormat(DateTime dt) {
    final utc = dt.toUtc();
    return '${utc.year}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}_'
        '${utc.hour.toString().padLeft(2, '0')}-'
        '${utc.minute.toString().padLeft(2, '0')}-'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  // Estrae lo stream ID numerico dall'URL Xtream
  static String _extractStreamId(String url) {
    final parts = url.split('/');
    final last = parts.last;
    // Rimuovi estensione (.ts, .m3u8, ecc.)
    final dot = last.lastIndexOf('.');
    return dot >= 0 ? last.substring(0, dot) : last;
  }

  /// Verifica se un programma è ancora recuperabile (entro i giorni di archivio)
  static bool isCatchupAvailable(Channel channel, EPGProgram program) {
    if (!channel.hasCatchup) return false;
    final days = channel.catchupDays ?? 3;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return program.start.isAfter(cutoff) && program.isPast;
  }
}
