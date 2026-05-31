import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/vod_item.dart';
import '../providers/channel_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Cerca canali, film, serie...',
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () =>
                  ref.read(searchQueryProvider.notifier).state = '',
            ),
        ],
      ),
      body: query.isEmpty
          ? const Center(
              child: Text('Digita per cercare canali, film o serie'),
            )
          : resultsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Errore: $e')),
              data: (results) {
                final live = results.live;
                final movies = results.movies;
                final series = results.series;
                final total = live.length + movies.length + series.length;

                if (total == 0) {
                  return const Center(child: Text('Nessun risultato'));
                }

                // Build a flat list with section headers
                final items = <_SearchItem>[];
                if (live.isNotEmpty) {
                  items.add(_SearchItem.header('Live TV (${live.length})'));
                  for (final ch in live) {
                    items.add(_SearchItem.channel(ch));
                  }
                }
                if (movies.isNotEmpty) {
                  items.add(_SearchItem.header('Film (${movies.length})'));
                  for (final v in movies) {
                    items.add(_SearchItem.vod(v));
                  }
                }
                if (series.isNotEmpty) {
                  items.add(_SearchItem.header('Serie TV (${series.length})'));
                  for (final v in series) {
                    items.add(_SearchItem.vod(v));
                  }
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    if (item.isHeader) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          item.label!,
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    if (item.channel != null) {
                      final ch = item.channel!;
                      return ListTile(
                        leading: const Icon(Icons.tv),
                        title: Text(ch.name),
                        subtitle: Text(ch.group ?? ''),
                        onTap: () => context.go('/player', extra: {
                          'url': ch.streamUrl,
                          'title': ch.name,
                          'channelId': ch.epgId ?? ch.id,
                        }),
                      );
                    }
                    final vod = item.vodItem!;
                    return ListTile(
                      leading: Icon(
                        vod.type == VodType.series
                            ? Icons.live_tv
                            : Icons.movie,
                      ),
                      title: Text(vod.name),
                      subtitle: Text(vod.year ?? ''),
                      onTap: () {
                        if (vod.type == VodType.series) {
                          context.go('/series', extra: vod);
                        } else if (vod.streamUrl != null) {
                          context.go('/player', extra: {
                            'url': vod.streamUrl!,
                            'title': vod.name,
                          });
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SearchItem {
  final bool isHeader;
  final String? label;
  final Channel? channel;
  final VodItem? vodItem;

  const _SearchItem._({
    required this.isHeader,
    this.label,
    this.channel,
    this.vodItem,
  });

  factory _SearchItem.header(String label) =>
      _SearchItem._(isHeader: true, label: label);
  factory _SearchItem.channel(Channel ch) =>
      _SearchItem._(isHeader: false, channel: ch);
  factory _SearchItem.vod(VodItem v) =>
      _SearchItem._(isHeader: false, vodItem: v);
}
