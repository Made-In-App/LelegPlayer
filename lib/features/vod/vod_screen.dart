import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/vod_item.dart';
import '../../data/models/playlist.dart';
import '../../data/services/xtream_service.dart';
import '../providers/channel_provider.dart';

final _vodProvider = FutureProvider<List<VodItem>>((ref) async {
  final playlists = ref.watch(playlistsProvider);
  final all = <VodItem>[];
  for (final pl in playlists) {
    if (pl.type == PlaylistType.xtream) {
      final svc = XtreamService(pl);
      try {
        all.addAll(await svc.getVodStreams());
      } catch (_) {}
    }
  }
  return all;
});

class VodScreen extends ConsumerWidget {
  const VodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vodAsync = ref.watch(_vodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Film & Serie')),
      body: vodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
                child: Text(
                    'Nessun contenuto VOD.\nAssicurati di avere una playlist Xtream Codes.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return _VodCard(
                item: item,
                onTap: item.streamUrl != null
                    ? () => context.go('/player', extra: {
                          'url': item.streamUrl!,
                          'title': item.name,
                        })
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _VodCard extends StatelessWidget {
  final VodItem item;
  final VoidCallback? onTap;

  const _VodCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: item.cover != null
                  ? CachedNetworkImage(
                      imageUrl: item.cover!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.movie, size: 48),
                    )
                  : const Center(child: Icon(Icons.movie, size: 48)),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.year != null)
                    Text(item.year!,
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
