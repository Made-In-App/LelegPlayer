import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/epg_program.dart';
import '../models/playlist.dart';
import '../parsers/xmltv_parser.dart';
import '../services/xtream_service.dart';

/// Stato del sync EPG
enum EpgSyncStatus { idle, loading, done, error }

class EpgSyncState {
  final EpgSyncStatus status;
  final String? message;
  final Map<String, List<EPGProgram>> data;
  const EpgSyncState({
    this.status = EpgSyncStatus.idle,
    this.message,
    this.data = const {},
  });
  EpgSyncState copyWith({EpgSyncStatus? status, String? message, Map<String, List<EPGProgram>>? data}) =>
      EpgSyncState(
        status: status ?? this.status,
        message: message ?? this.message,
        data: data ?? this.data,
      );
}

/// Provider che gestisce l'EPG globale e il suo sync
class EpgSyncNotifier extends AsyncNotifier<Map<String, List<EPGProgram>>> {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
  ));

  @override
  Future<Map<String, List<EPGProgram>>> build() async {
    // Carica EPG cached da Hive se disponibile
    final cached = await _loadCached();
    if (cached.isNotEmpty) {
      // Aggiorna in background senza bloccare la UI
      _syncInBackground();
      return cached;
    }
    return await _sync();
  }

  /// Forza un refresh completo
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _sync());
  }

  Future<Map<String, List<EPGProgram>>> _sync() async {
    final box = Hive.box<PlaylistSource>('playlists');
    final playlists = box.values.where((p) => p.enabled).toList();
    final result = <String, List<EPGProgram>>{};

    for (final playlist in playlists) {
      try {
        // 1. URL EPG esplicito nella playlist
        if (playlist.epgUrl != null && playlist.epgUrl!.isNotEmpty) {
          final epg = await _fetchXmltv(playlist.epgUrl!);
          _merge(result, epg);
        }

        // 2. Xtream: ottieni URL XMLTV dall'API
        if (playlist.type == PlaylistType.xtream) {
          final svc = XtreamService(playlist);
          try {
            final xmltvUrl = await svc.getXmltv();
            if (xmltvUrl != null && xmltvUrl.isNotEmpty) {
              final epg = await _fetchXmltv(xmltvUrl);
              _merge(result, epg);
            }
          } catch (_) {}
        }
      } catch (_) {}
    }

    await _saveCache(result);
    return result;
  }

  void _syncInBackground() {
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        final fresh = await _sync();
        if (fresh.isNotEmpty) state = AsyncData(fresh);
      } catch (_) {}
    });
  }

  Future<Map<String, List<EPGProgram>>> _fetchXmltv(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data!;
    String xml;
    try {
      xml = utf8.decode(GZipCodec().decode(bytes));
    } catch (_) {
      xml = utf8.decode(bytes);
    }
    return XMLTVParser.parse(xml);
  }

  void _merge(Map<String, List<EPGProgram>> target, Map<String, List<EPGProgram>> source) {
    for (final entry in source.entries) {
      if (target.containsKey(entry.key)) {
        target[entry.key]!.addAll(entry.value);
        target[entry.key]!.sort((a, b) => a.start.compareTo(b.start));
      } else {
        target[entry.key] = entry.value;
      }
    }
  }

  // ── Cache Hive semplice (JSON) ───────────────────────────

  Future<Map<String, List<EPGProgram>>> _loadCached() async {
    try {
      final box = await Hive.openBox('epg_cache');
      final ts = box.get('timestamp') as int?;
      if (ts == null) return {};
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > const Duration(hours: 12).inMilliseconds) return {};

      final raw = box.get('data') as Map?;
      if (raw == null) return {};

      final result = <String, List<EPGProgram>>{};
      raw.forEach((k, v) {
        final list = (v as List).map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return EPGProgram(
            channelId: m['channelId'],
            title: m['title'],
            description: m['description'],
            start: DateTime.fromMillisecondsSinceEpoch(m['start']),
            end: DateTime.fromMillisecondsSinceEpoch(m['end']),
            category: m['category'],
            hasCatchup: m['hasCatchup'] ?? false,
          );
        }).toList();
        result[k as String] = list;
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveCache(Map<String, List<EPGProgram>> data) async {
    try {
      final box = await Hive.openBox('epg_cache');
      final serialized = <String, List<Map>>{};
      data.forEach((k, programs) {
        serialized[k] = programs.map((p) => {
          'channelId': p.channelId,
          'title': p.title,
          'description': p.description,
          'start': p.start.millisecondsSinceEpoch,
          'end': p.end.millisecondsSinceEpoch,
          'category': p.category,
          'hasCatchup': p.hasCatchup,
        }).toList();
      });
      await box.put('data', serialized);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

final epgSyncProvider =
    AsyncNotifierProvider<EpgSyncNotifier, Map<String, List<EPGProgram>>>(
        EpgSyncNotifier.new);

/// Helper: programma in corso per un channelId
extension EpgLookup on Map<String, List<EPGProgram>> {
  EPGProgram? nowFor(String channelId) =>
      this[channelId]?.where((p) => p.isNow).firstOrNull;

  EPGProgram? nextFor(String channelId) {
    final now = DateTime.now();
    return this[channelId]?.where((p) => p.start.isAfter(now)).firstOrNull;
  }

  List<EPGProgram> rangeFor(String channelId, DateTime from, DateTime to) =>
      (this[channelId] ?? [])
          .where((p) => p.end.isAfter(from) && p.start.isBefore(to))
          .toList();
}
