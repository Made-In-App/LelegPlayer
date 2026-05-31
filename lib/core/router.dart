import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/channels/channels_screen.dart';
import '../features/epg/epg_screen.dart';
import '../features/player/player_screen.dart';
import '../features/vod/vod_screen.dart';
import '../features/vod/series_detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/playlists/playlists_screen.dart';
import '../features/settings/settings_screen.dart';
import '../data/models/vod_item.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(path: '/', builder: (c, s) => const ChannelsScreen()),
          GoRoute(path: '/epg', builder: (c, s) => const EpgScreen()),
          GoRoute(path: '/vod', builder: (c, s) => const VodScreen()),
          GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
          GoRoute(path: '/playlists', builder: (c, s) => const PlaylistsScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return PlayerScreen(
            streamUrl: extra['url'] as String,
            title: extra['title'] as String? ?? '',
            channelId: extra['channelId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/series',
        builder: (context, state) {
          final series = state.extra as VodItem;
          return SeriesDetailScreen(series: series);
        },
      ),
    ],
  );
});
