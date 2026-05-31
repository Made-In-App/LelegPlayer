import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/playlist.dart';
import '../../data/models/vod_item.dart';
import '../../data/services/xtream_service.dart';
import '../../shared/widgets/tv_focusable.dart';
import '../providers/channel_provider.dart';

final _seriesInfoProvider =
    FutureProvider.family<Map<String, dynamic>, ({String seriesId, String playlistId})>(
        (ref, args) async {
  final playlists = ref.watch(playlistsProvider).valueOrNull ?? [];
  final playlist = playlists.firstWhere((p) => p.id == args.playlistId);
  final svc = XtreamService(playlist);
  return svc.getSeriesInfo(args.seriesId);
});

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final VodItem series;
  const SeriesDetailScreen({super.key, required this.series});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  int _selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(_seriesInfoProvider((
      seriesId: widget.series.id,
      playlistId: widget.series.playlistId ?? '',
    )));

    return Scaffold(
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (info) {
          final seasons = _parseSeasons(info);
          final episodes = seasons[_selectedSeason] ?? [];

          return CustomScrollView(
            slivers: [
              // ── Header con copertina ──────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(widget.series.name,
                      style: const TextStyle(fontSize: 14)),
                  background: widget.series.cover != null
                      ? ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.5, 1.0],
                          ).createShader(rect),
                          child: CachedNetworkImage(
                            imageUrl: widget.series.cover!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                ),
              ),

              // ── Info serie ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.series.genre != null ||
                          widget.series.year != null)
                        Text(
                          [widget.series.year, widget.series.genre]
                              .whereType<String>()
                              .join(' · '),
                          style: const TextStyle(
                              color: AppTheme.onSurface, fontSize: 13),
                        ),
                      if (widget.series.plot != null) ...[
                        const SizedBox(height: 8),
                        Text(widget.series.plot!,
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Selettore stagione ───────────────────────
              if (seasons.length > 1)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: seasons.keys.map((season) {
                        final selected = season == _selectedSeason;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TvFocusable(
                            onTap: () =>
                                setState(() => _selectedSeason = season),
                            child: Chip(
                              label: Text('Stagione $season'),
                              backgroundColor: selected
                                  ? AppTheme.accent
                                  : AppTheme.surface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              // ── Lista episodi ─────────────────────────────
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final ep = episodes[i];
                    return TvFocusable(
                      onTap: ep.streamUrl != null
                          ? () => context.go('/player', extra: {
                                'url': ep.streamUrl!,
                                'title':
                                    'S${ep.seasonNum}E${ep.episodeNum} — ${ep.name}',
                              })
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surface,
                          child: Text('${ep.episodeNum}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                        title: Text(ep.name),
                        subtitle: ep.plot != null
                            ? Text(ep.plot!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))
                            : null,
                        trailing: ep.streamUrl != null
                            ? const Icon(Icons.play_circle_outline,
                                color: AppTheme.accent)
                            : null,
                      ),
                    );
                  },
                  childCount: episodes.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<int, List<VodItem>> _parseSeasons(Map<String, dynamic> info) {
    final result = <int, List<VodItem>>{};
    final episodes = info['episodes'] as Map? ?? {};

    episodes.forEach((seasonKey, episodeList) {
      final season = int.tryParse(seasonKey.toString()) ?? 1;
      final list = (episodeList as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final info2 = m['info'] as Map? ?? {};
        final ext = m['container_extension'] as String? ?? 'mkv';
        return VodItem(
          id: m['id'].toString(),
          name: m['title'] as String? ?? 'Episodio',
          plot: info2['plot'] as String?,
          type: VodType.episode,
          streamUrl: _buildEpisodeUrl(m),
          containerExtension: ext,
          seriesId: widget.series.id,
          seasonNum: season,
          episodeNum: int.tryParse(m['episode_num'].toString()) ?? 0,
          playlistId: widget.series.playlistId,
        );
      }).toList()
        ..sort((a, b) => (a.episodeNum ?? 0).compareTo(b.episodeNum ?? 0));
      result[season] = list;
    });

    return Map.fromEntries(result.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
  }

  String? _buildEpisodeUrl(Map<String, dynamic> ep) {
    final playlists = ref.read(playlistsProvider).valueOrNull ?? [];
    if (widget.series.playlistId == null) return null;
    try {
      final playlist = playlists
          .firstWhere((p) => p.id == widget.series.playlistId);
      if (playlist.type != PlaylistType.xtream) return null;
      final id = ep['id'].toString();
      final ext = ep['container_extension'] as String? ?? 'mkv';
      return '${playlist.serverUrl}/series/${playlist.username}/${playlist.password}/$id.$ext';
    } catch (_) {
      return null;
    }
  }
}
