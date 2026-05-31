import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/vod_item.dart';
import '../providers/channel_provider.dart';

class VodScreen extends ConsumerStatefulWidget {
  const VodScreen({super.key});

  @override
  ConsumerState<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends ConsumerState<VodScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Film & Serie'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.movie), text: 'Film'),
            Tab(icon: Icon(Icons.tv), text: 'Serie TV'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _VodGrid(provider: moviesProvider, icon: Icons.movie),
          _VodGrid(provider: seriesProvider, icon: Icons.live_tv),
        ],
      ),
    );
  }
}

class _VodGrid extends ConsumerWidget {
  final FutureProvider<List<VodItem>> provider;
  final IconData icon;

  const _VodGrid({required this.provider, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: AppTheme.onSurface),
                const SizedBox(height: 12),
                const Text(
                  'Nessun contenuto trovato.\nAggiungi una playlist M3U o Xtream Codes.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
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
              onTap: () {
                if (item.type == VodType.series) {
                  context.go('/series', extra: item);
                } else if (item.streamUrl != null) {
                  context.go('/player', extra: {
                    'url': item.streamUrl!,
                    'title': item.name,
                  });
                }
              },
            );
          },
        );
      },
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
                          Center(child: Icon(Icons.movie, size: 48)),
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
