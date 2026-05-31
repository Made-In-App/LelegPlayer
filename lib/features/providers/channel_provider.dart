import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../../data/models/channel.dart';
import '../../data/models/epg_program.dart';
import '../../data/models/playlist.dart';
import '../../data/parsers/m3u_parser.dart';
import '../../data/services/xtream_service.dart';
import '../../data/services/epg_service.dart';

/// Tutte le playlist salvate
final playlistsProvider = Provider<List<PlaylistSource>>((ref) {
  final box = Hive.box<PlaylistSource>('playlists');
  return box.values.where((p) => p.enabled).toList();
});

/// Tutti i canali da tutte le playlist abilitate
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final playlists = ref.watch(playlistsProvider);
  if (playlists.isEmpty) return [];

  final allChannels = <Channel>[];
  final dio = Dio();

  for (final playlist in playlists) {
    try {
      if (playlist.type == PlaylistType.m3u && playlist.m3uUrl != null) {
        final response = await dio.get<String>(playlist.m3uUrl!);
        final channels = M3UParser.parse(
          response.data!,
          playlistId: playlist.id,
        );
        allChannels.addAll(channels);
      } else if (playlist.type == PlaylistType.xtream) {
        final service = XtreamService(playlist);
        final channels = await service.getLiveStreams();
        allChannels.addAll(channels);
      }
    } catch (e) {
      // Continua con le altre playlist in caso di errore
    }
  }

  return allChannels;
});

/// EPG corrente: channelId → programmi
final currentEpgProvider = StateProvider<Map<String, List<EPGProgram>>>((ref) => {});

/// Carica EPG per una specifica playlist
final epgLoaderProvider = FutureProvider.family<void, String>((ref, epgUrl) async {
  final service = EpgService();
  final epg = await service.fetchAndParse(epgUrl);
  ref.read(currentEpgProvider.notifier).update((state) {
    final updated = Map<String, List<EPGProgram>>.from(state);
    for (final entry in epg.entries) {
      updated.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }
    return updated;
  });
});

/// Ricerca globale tra i canali
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<Channel>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) return [];

  final channelsAsync = ref.watch(channelsProvider);
  return channelsAsync.when(
    data: (channels) =>
        channels.where((c) => c.name.toLowerCase().contains(query)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
