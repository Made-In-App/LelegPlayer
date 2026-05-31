import 'package:xml/xml.dart';
import '../models/epg_program.dart';

/// Parser per file XMLTV (EPG)
/// Supporta sia plain XML che (con pre-processing) gzip
class XMLTVParser {
  /// Parsa l'XML e restituisce mappa channelId → programmi ordinati per orario
  static Map<String, List<EPGProgram>> parse(String xmlContent) {
    final result = <String, List<EPGProgram>>{};

    try {
      final doc = XmlDocument.parse(xmlContent);
      final programmes = doc.findAllElements('programme');

      for (final prog in programmes) {
        final channelId = prog.getAttribute('channel') ?? '';
        final startStr = prog.getAttribute('start') ?? '';
        final stopStr = prog.getAttribute('stop') ?? '';

        final start = _parseDate(startStr);
        final stop = _parseDate(stopStr);
        if (start == null || stop == null) continue;

        final title = prog.findElements('title').firstOrNull?.innerText ?? '';
        final desc = prog.findElements('desc').firstOrNull?.innerText;
        final category = prog.findElements('category').firstOrNull?.innerText;
        final icon = prog.findElements('icon').firstOrNull?.getAttribute('src');

        final program = EPGProgram(
          channelId: channelId,
          title: title,
          description: desc,
          start: start,
          end: stop,
          category: category,
          icon: icon,
        );

        result.putIfAbsent(channelId, () => []).add(program);
      }

      // Ordina per orario
      for (final list in result.values) {
        list.sort((a, b) => a.start.compareTo(b.start));
      }
    } catch (e) {
      // Log error in production
    }

    return result;
  }

  /// Formato XMLTV: 20240101120000 +0100
  static DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    try {
      // Rimuovi spazi e prendi i componenti
      final parts = s.trim().split(' ');
      final datePart = parts[0];
      final tzPart = parts.length > 1 ? parts[1] : '+0000';

      if (datePart.length < 14) return null;

      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(datePart.substring(8, 10));
      final minute = int.parse(datePart.substring(10, 12));
      final second = int.parse(datePart.substring(12, 14));

      // Offset timezone
      final sign = tzPart.startsWith('-') ? -1 : 1;
      final tzHours = int.tryParse(tzPart.substring(1, 3)) ?? 0;
      final tzMinutes = int.tryParse(tzPart.substring(3, 5)) ?? 0;
      final tzOffset = sign * (tzHours * 60 + tzMinutes);

      return DateTime.utc(year, month, day, hour, minute, second)
          .subtract(Duration(minutes: tzOffset));
    } catch (_) {
      return null;
    }
  }
}
