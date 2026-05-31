import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import '../../data/models/channel.dart';
import '../../data/models/epg_program.dart';
import '../../data/models/playlist.dart';
import '../../data/models/vod_item.dart';
import '../../data/parsers/m3u_parser.dart';
import '../../data/services/xtream_service.dart';
import '../../data/services/epg_service.dart';

// ── Playlist ─────────────────────────────────────────────────

final playlistsProvider = Provider<List<PlaylistSource>>((ref) {
  final box = Hive.box<PlaylistSource>('playlists');
  return box.values.where((p) => p.enabled).toList();
});

// ── Contenuto grezzo da tutte le playlist ────────────────────

class _AllContent {
  final List<Channel> live;
  final List<VodItem> movies;
  final List<VodItem> series;
  final List<String> errors;
  const _AllContent({
    this.live = const [],
    this.movies = const [],
    this.series = const [],
    this.errors = const [],
  });
}

final _allContentProvider = FutureProvider<_AllContent>((ref) async {
  final playlists = ref.watch(playlistsProvider);
  if (playlists.isEmpty) return const _AllContent();

  final live = <Channel>[];
  final movies = <VodItem>[];
  final series = <VodItem>[];
  final errors = <String>[];
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
  ));

  for (final playlist in playlists) {
    try {
      if (playlist.type == PlaylistType.m3u && playlist.m3uUrl != null) {
        // ── M3U: scarica e categorizza ──────────────────────
        final response = await dio.get<String>(
          playlist.m3uUrl!,
          options: Options(responseType: ResponseType.plain),
        );
        final content = response.data ?? '';
        final all = M3UParser.parse(content, playlistId: playlist.id);

        for (final ch in all) {
          final type = _detectType(ch.streamUrl, ch.group);
          if (type == _ContentType.movie) {
            movies.add(_channelToVod(ch, VodType.movie));
          } else if (type == _ContentType.series) {
            series.add(_channelToVod(ch, VodType.series));
          } else {
            live.add(ch);
          }
        }
      } else if (playlist.type == PlaylistType.xtream) {
        // ── Xtream: API separate per ogni tipo ──────────────
        final svc = XtreamService(playlist);
        try {
          live.addAll(await svc.getLiveStreams());
        } catch (e) {
          errors.add('${playlist.name} live: $e');
        }
        try {
          movies.addAll(await svc.getVodStreams());
        } catch (e) {
          errors.add('${playlist.name} film: $e');
        }
        try {
          series.addAll(await svc.getSeries());
        } catch (e) {
          errors.add('${playlist.name} serie: $e');
        }
      }
    } catch (e) {
      errors.add('${playlist.name}: $e');
    }
  }

  return _AllContent(live: live, movies: movies, series: series, errors: errors);
});

// ── Provider pubblici ─────────────────────────────────────────

final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  final content = await ref.watch(_allContentProvider.future);
  return content.live;
});

final moviesProvider = FutureProvider<List<VodItem>>((ref) async {
  final content = await ref.watch(_allContentProvider.future);
  return content.movies;
});

final seriesProvider = FutureProvider<List<VodItem>>((ref) async {
  final content = await ref.watch(_allContentProvider.future);
  return content.series;
});

final loadErrorsProvider = FutureProvider<List<String>>((ref) async {
  final content = await ref.watch(_allContentProvider.future);
  return content.errors;
});

// ── Rilevamento tipo dal URL / gruppo ─────────────────────────

enum _ContentType { live, movie, series }

_ContentType _detectType(String url, String? group) {
  final u = url.toLowerCase();
  final g = (group ?? '').toLowerCase();

  // Pattern URL Xtream-style
  if (u.contains('/movie/')) return _ContentType.movie;
  if (u.contains('/series/')) return _ContentType.series;
  if (u.contains('/live/')) return _ContentType.live;

  // Estensioni tipiche VOD
  if (u.endsWith('.mkv') || u.endsWith('.mp4') || u.endsWith('.avi') ||
      u.endsWith('.mov') || u.endsWith('.wmv')) return _ContentType.movie;

  // Pattern group-title comuni
  final movieGroups = ['film', 'movie', 'vod', 'cinema', 'films'];
  final seriesGroups = ['serie', 'series', 'tv show', 'tvshow', 'sitcom', 'drama'];
  if (movieGroups.any((k) => g.contains(k))) return _ContentType.movie;
  if (seriesGroups.any((k) => g.contains(k))) return _ContentType.series;

  return _ContentType.live;
}

VodItem _channelToVod(Channel ch, VodType type) => VodItem(
      id: ch.id,
      name: ch.name,
      cover: ch.logo,
      type: type,
      streamUrl: ch.streamUrl,
      playlistId: ch.playlistId,
    );

// ── EPG ───────────────────────────────────────────────────────

final currentEpgProvider = StateProvider<Map<String, List<EPGProgram>>>((ref) => {});

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

// ── Ricerca globale ───────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider =
    FutureProvider<({List<Channel> live, List<VodItem> movies, List<VodItem> series})>(
        (ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty) {
    return (live: <Channel>[], movies: <VodItem>[], series: <VodItem>[]);
  }
  final content = await ref.watch(_allContentProvider.future);
  return (
    live: content.live.where((c) => c.name.toLowerCase().contains(query)).toList(),
    movies: content.movies.where((v) => v.name.toLowerCase().contains(query)).toList(),
    series: content.series.where((v) => v.name.toLowerCase().contains(query)).toList(),
  );
});
