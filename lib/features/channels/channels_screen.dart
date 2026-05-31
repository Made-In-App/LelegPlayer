import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/epg_program.dart';
import '../../data/services/epg_sync_service.dart';
import '../../data/services/favorites_service.dart';
import '../../shared/widgets/tv_focusable.dart';
import '../providers/channel_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedGroup;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final epg = ref.watch(epgSyncProvider).valueOrNull ?? {};
    final errorsAsync = ref.watch(loadErrorsProvider);
    final errors = errorsAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna EPG',
            onPressed: () => ref.read(epgSyncProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.live_tv), text: 'Tutti'),
            Tab(icon: Icon(Icons.favorite), text: 'Preferiti'),
            Tab(icon: Icon(Icons.history), text: 'Recenti'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner errori (solo se ci sono problemi)
          if (errors.isNotEmpty)
            Material(
              color: Colors.orange.shade900,
              child: ExpansionTile(
                leading: const Icon(Icons.warning_amber, color: Colors.white),
                title: Text(
                  '${errors.length} errore/i di caricamento',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                children: errors
                    .map((e) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(e,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ))
                    .toList(),
              ),
            ),

          // Contenuto principale
          Expanded(
            child: channelsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(error: e.toString()),
              data: (channels) {
                final groups = channels
                    .map((c) => c.group ?? 'Senza categoria')
                    .toSet()
                    .toList()
                  ..sort();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _AllChannelsTab(
                      channels: channels,
                      groups: groups,
                      selectedGroup: _selectedGroup,
                      onGroupSelected: (g) =>
                          setState(() => _selectedGroup = g),
                      epg: epg,
                    ),
                    _FavoritesTab(epg: epg),
                    _HistoryTab(epg: epg),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────

class _AllChannelsTab extends StatelessWidget {
  final List<Channel> channels;
  final List<String> groups;
  final String? selectedGroup;
  final ValueChanged<String?> onGroupSelected;
  final Map<String, List<EPGProgram>> epg;

  const _AllChannelsTab({
    required this.channels,
    required this.groups,
    this.selectedGroup,
    required this.onGroupSelected,
    required this.epg,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = selectedGroup == null
        ? channels
        : channels.where((c) => c.group == selectedGroup).toList();
    final isWide = MediaQuery.of(context).size.width > 600;

    return Row(
      children: [
        if (isWide)
          SizedBox(
            width: 180,
            child: _GroupSidebar(
                groups: groups,
                selected: selectedGroup,
                onSelect: onGroupSelected),
          ),
        Expanded(
          child: Column(
            children: [
              if (!isWide)
                _GroupDropdown(
                    groups: groups,
                    selected: selectedGroup,
                    onSelect: onGroupSelected),
              Expanded(child: _ChannelList(channels: filtered, epg: epg)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  final Map<String, List<EPGProgram>> epg;
  const _FavoritesTab({required this.epg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favsAsync = ref.watch(favoritesProvider);
    return favsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (favs) => favs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: AppTheme.onSurface),
                  SizedBox(height: 12),
                  Text('Nessun preferito'),
                  Text(
                    'Tieni premuto su un canale per aggiungerlo',
                    style:
                        TextStyle(color: AppTheme.onSurface, fontSize: 12),
                  ),
                ],
              ),
            )
          : _ChannelList(channels: favs, epg: epg),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  final Map<String, List<EPGProgram>> epg;
  const _HistoryTab({required this.epg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final histAsync = ref.watch(watchHistoryProvider);
    return histAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (history) => history.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.onSurface),
                  SizedBox(height: 12),
                  Text('Nessun canale visto di recente'),
                ],
              ),
            )
          : Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Cancella cronologia'),
                    onPressed: () =>
                        ref.read(watchHistoryProvider.notifier).clear(),
                  ),
                ),
                Expanded(child: _ChannelList(channels: history, epg: epg)),
              ],
            ),
    );
  }
}

// ── Lista canali ──────────────────────────────────────────────

class _ChannelList extends ConsumerWidget {
  final List<Channel> channels;
  final Map<String, List<EPGProgram>> epg;
  const _ChannelList({required this.channels, required this.epg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, i) {
        final ch = channels[i];
        final epgId = ch.epgId ?? ch.id;
        final now = epg.nowFor(epgId);
        final next = epg.nextFor(epgId);
        return _ChannelTile(
          channel: ch,
          nowPlaying: now,
          nextProgram: next,
          onTap: () {
            ref.read(watchHistoryProvider.notifier).add(ch);
            context.go('/player', extra: {
              'url': ch.streamUrl,
              'title': ch.name,
              'channelId': epgId,
            });
          },
          onLongPress: () => ref.read(favoritesProvider.notifier).toggle(ch),
        );
      },
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final EPGProgram? nowPlaying;
  final EPGProgram? nextProgram;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ChannelTile({
    required this.channel,
    this.nowPlaying,
    this.nextProgram,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: channel.logo != null
                  ? CachedNetworkImage(
                      imageUrl: channel.logo!,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.tv, size: 32),
                    )
                  : const Icon(Icons.tv, size: 32),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(channel.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                      if (channel.hasCatchup)
                        const Icon(Icons.history,
                            size: 14, color: AppTheme.accent),
                    ],
                  ),
                  if (nowPlaying != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '▶ ${nowPlaying!.title}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    LinearProgressIndicator(
                      value: nowPlaying!.progress,
                      backgroundColor: AppTheme.epgPast,
                      valueColor:
                          const AlwaysStoppedAnimation(AppTheme.accent),
                      minHeight: 2,
                    ),
                    if (nextProgram != null)
                      Text(
                        'Dopo: ${nextProgram!.title}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sidebar / Dropdown gruppi ─────────────────────────────────

class _GroupSidebar extends StatelessWidget {
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _GroupSidebar(
      {required this.groups, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: ListView(
        children: [
          TvFocusable(
            onTap: () => onSelect(null),
            child: ListTile(
                title: const Text('Tutti'),
                selected: selected == null,
                dense: true),
          ),
          ...groups.map((g) => TvFocusable(
                onTap: () => onSelect(g),
                child: ListTile(
                    title: Text(g, overflow: TextOverflow.ellipsis),
                    selected: selected == g,
                    dense: true),
              )),
        ],
      ),
    );
  }
}

class _GroupDropdown extends StatelessWidget {
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _GroupDropdown(
      {required this.groups, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: DropdownButtonFormField<String?>(
        value: selected,
        hint: const Text('Tutti i gruppi'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tutti')),
          ...groups.map((g) => DropdownMenuItem(value: g, child: Text(g))),
        ],
        onChanged: onSelect,
      ),
    );
  }
}

// ── Errore ────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/playlists'),
            child: const Text('Aggiungi playlist'),
          ),
        ],
      ),
    );
  }
}
