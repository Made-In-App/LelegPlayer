import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/channel_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

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
          : results.isEmpty
              ? const Center(child: Text('Nessun risultato'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final ch = results[i];
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
                  },
                ),
    );
  }
}
