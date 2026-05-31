import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/channel.dart';

/// Gestisce preferiti e cronologia visione in Hive
class FavoritesService {
  static const _favBox = 'favorites';
  static const _histBox = 'watch_history';

  // ── Preferiti ────────────────────────────────────────────

  static Future<void> addFavorite(Channel channel) async {
    final box = await Hive.openBox(_favBox);
    await box.put(channel.id, _channelToMap(channel));
  }

  static Future<void> removeFavorite(String channelId) async {
    final box = await Hive.openBox(_favBox);
    await box.delete(channelId);
  }

  static Future<bool> isFavorite(String channelId) async {
    final box = await Hive.openBox(_favBox);
    return box.containsKey(channelId);
  }

  static Future<List<Channel>> getFavorites() async {
    final box = await Hive.openBox(_favBox);
    return box.values
        .map((v) => _channelFromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  // ── Cronologia ───────────────────────────────────────────

  static Future<void> addToHistory(Channel channel) async {
    final box = await Hive.openBox(_histBox);
    final entry = _channelToMap(channel);
    entry['watchedAt'] = DateTime.now().millisecondsSinceEpoch;
    // Metti in cima, rimuovi duplicati
    await box.delete(channel.id);
    await box.put(channel.id, entry);
    // Mantieni max 100 voci
    if (box.length > 100) {
      final oldest = box.keys.first;
      await box.delete(oldest);
    }
  }

  static Future<List<Channel>> getHistory() async {
    final box = await Hive.openBox(_histBox);
    final entries = box.values.toList()
      ..sort((a, b) {
        final ta = (a as Map)['watchedAt'] as int? ?? 0;
        final tb = (b as Map)['watchedAt'] as int? ?? 0;
        return tb.compareTo(ta); // più recenti prima
      });
    return entries
        .map((v) => _channelFromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  static Future<void> clearHistory() async {
    final box = await Hive.openBox(_histBox);
    await box.clear();
  }

  // ── Serializzazione ──────────────────────────────────────

  static Map<String, dynamic> _channelToMap(Channel c) => {
        'id': c.id,
        'name': c.name,
        'logo': c.logo,
        'streamUrl': c.streamUrl,
        'group': c.group,
        'epgId': c.epgId,
        'hasCatchup': c.hasCatchup,
        'catchupDays': c.catchupDays,
        'playlistId': c.playlistId,
      };

  static Channel _channelFromMap(Map<String, dynamic> m) => Channel(
        id: m['id'] as String,
        name: m['name'] as String,
        logo: m['logo'] as String?,
        streamUrl: m['streamUrl'] as String,
        group: m['group'] as String?,
        epgId: m['epgId'] as String?,
        hasCatchup: m['hasCatchup'] as bool? ?? false,
        catchupDays: m['catchupDays'] as int?,
        playlistId: m['playlistId'] as String?,
      );
}

// ── Riverpod Providers ───────────────────────────────────────

final favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<Channel>>(FavoritesNotifier.new);

class FavoritesNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() => FavoritesService.getFavorites();

  Future<void> toggle(Channel channel) async {
    final isFav = await FavoritesService.isFavorite(channel.id);
    if (isFav) {
      await FavoritesService.removeFavorite(channel.id);
    } else {
      await FavoritesService.addFavorite(channel);
    }
    ref.invalidateSelf();
  }

  Future<bool> isFavorite(String channelId) =>
      FavoritesService.isFavorite(channelId);
}

final watchHistoryProvider =
    AsyncNotifierProvider<WatchHistoryNotifier, List<Channel>>(WatchHistoryNotifier.new);

class WatchHistoryNotifier extends AsyncNotifier<List<Channel>> {
  @override
  Future<List<Channel>> build() => FavoritesService.getHistory();

  Future<void> add(Channel channel) async {
    await FavoritesService.addToHistory(channel);
    ref.invalidateSelf();
  }

  Future<void> clear() async {
    await FavoritesService.clearHistory();
    ref.invalidateSelf();
  }
}
