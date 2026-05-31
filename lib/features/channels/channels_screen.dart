import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/epg_program.dart';
import '../providers/channel_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final epg = ref.watch(currentEpgProvider);

    return channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(error: e.toString()),
      data: (channels) {
        final groups = channels
            .map((c) => c.group ?? 'Senza categoria')
            .toSet()
            .toList()
          ..sort();

        final filtered = _selectedGroup == null
            ? channels
            : channels.where((c) => c.group == _selectedGroup).toList();

        return Row(
          children: [
            // ── Sidebar gruppi ──────────────────────────────
            if (MediaQuery.of(context).size.width > 600)
              SizedBox(
                width: 200,
                child: _GroupList(
                  groups: groups,
                  selected: _selectedGroup,
                  onSelect: (g) => setState(() => _selectedGroup = g),
                ),
              ),

            // ── Lista canali ────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  if (MediaQuery.of(context).size.width <= 600)
                    _GroupDropdown(
                      groups: groups,
                      selected: _selectedGroup,
                      onSelect: (g) => setState(() => _selectedGroup = g),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final ch = filtered[i];
                        final nowPlaying = epg[ch.epgId ?? ch.id]
                            ?.where((p) => p.isNow)
                            .firstOrNull;
                        return _ChannelTile(
                          channel: ch,
                          nowPlaying: nowPlaying,
                          onTap: () => context.go('/player', extra: {
                            'url': ch.streamUrl,
                            'title': ch.name,
                            'channelId': ch.epgId ?? ch.id,
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _GroupList({required this.groups, this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceVariant,
      child: ListView(
        children: [
          ListTile(
            title: const Text('Tutti'),
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...groups.map((g) => ListTile(
                title: Text(g, overflow: TextOverflow.ellipsis),
                selected: selected == g,
                onTap: () => onSelect(g),
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

  const _GroupDropdown({required this.groups, this.selected, required this.onSelect});

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

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final EPGProgram? nowPlaying;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    this.nowPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: channel.logo != null
          ? CachedNetworkImage(
              imageUrl: channel.logo!,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorWidget: (_, __, ___) => const Icon(Icons.tv),
            )
          : const Icon(Icons.tv, size: 48),
      title: Text(channel.name),
      subtitle: nowPlaying != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nowPlaying!.title,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                LinearProgressIndicator(
                  value: nowPlaying!.progress,
                  backgroundColor: AppTheme.epgPast,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  minHeight: 2,
                ),
              ],
            )
          : null,
      trailing: channel.hasCatchup
          ? const Icon(Icons.history, size: 16, color: AppTheme.accent)
          : null,
      onTap: onTap,
    );
  }
}

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
          Text(error),
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
