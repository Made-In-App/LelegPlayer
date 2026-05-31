import 'package:dio/dio.dart';
import '../models/channel.dart';
import '../models/vod_item.dart';
import '../models/playlist.dart';

/// Client per l'API Xtream Codes
class XtreamService {
  final Dio _dio;
  final PlaylistSource playlist;

  XtreamService(this.playlist)
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
        ));

  String get _base =>
      '${playlist.serverUrl}/player_api.php?username=${playlist.username}&password=${playlist.password}';

  Future<Map<String, dynamic>> getUserInfo() async {
    final r = await _dio.get(_base);
    return r.data as Map<String, dynamic>;
  }

  // ── Live TV ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLiveCategories() async {
    final r = await _dio.get('$_base&action=get_live_categories');
    return List<Map<String, dynamic>>.from(r.data);
  }

  Future<List<Channel>> getLiveStreams({String? categoryId}) async {
    var url = '$_base&action=get_live_streams';
    if (categoryId != null) url += '&category_id=$categoryId';

    final r = await _dio.get(url);
    final data = List<Map<String, dynamic>>.from(r.data);

    return data.map((item) {
      final streamId = item['stream_id'].toString();
      return Channel(
        id: streamId,
        name: item['name'] ?? '',
        logo: item['stream_icon'],
        streamUrl: playlist.xtreamLiveUrl(int.parse(streamId)),
        group: item['category_id']?.toString(),
        epgId: item['epg_channel_id'],
        hasCatchup: (item['tv_archive'] ?? 0) == 1,
        catchupDays: int.tryParse(item['tv_archive_duration']?.toString() ?? ''),
        playlistId: playlist.id,
      );
    }).toList();
  }

  // ── VOD ──────────────────────────────────────────────────

  Future<List<VodItem>> getVodStreams({String? categoryId}) async {
    var url = '$_base&action=get_vod_streams';
    if (categoryId != null) url += '&category_id=$categoryId';

    final r = await _dio.get(url);
    final data = List<Map<String, dynamic>>.from(r.data);

    return data.map((item) {
      final streamId = item['stream_id'].toString();
      final ext = item['container_extension'] ?? 'mp4';
      return VodItem(
        id: streamId,
        name: item['name'] ?? '',
        cover: item['stream_icon'],
        year: item['year']?.toString(),
        rating: item['rating']?.toString(),
        type: VodType.movie,
        streamUrl: playlist.xtreamVodUrl(int.parse(streamId), ext),
        containerExtension: ext,
        playlistId: playlist.id,
      );
    }).toList();
  }

  // ── Series ───────────────────────────────────────────────

  Future<List<VodItem>> getSeries({String? categoryId}) async {
    var url = '$_base&action=get_series';
    if (categoryId != null) url += '&category_id=$categoryId';

    final r = await _dio.get(url);
    final data = List<Map<String, dynamic>>.from(r.data);

    return data.map((item) => VodItem(
          id: item['series_id'].toString(),
          name: item['name'] ?? '',
          cover: item['cover'],
          plot: item['plot'],
          genre: item['genre'],
          year: item['releaseDate']?.toString(),
          rating: item['rating']?.toString(),
          type: VodType.series,
          playlistId: playlist.id,
        )).toList();
  }

  Future<Map<String, dynamic>> getSeriesInfo(String seriesId) async {
    final r = await _dio.get('$_base&action=get_series_info&series_id=$seriesId');
    return r.data as Map<String, dynamic>;
  }

  // ── EPG ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getShortEpg(String streamId,
      {int limit = 4}) async {
    final r = await _dio
        .get('$_base&action=get_short_epg&stream_id=$streamId&limit=$limit');
    final epgData = r.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(epgData['epg_listings'] ?? []);
  }

  /// Restituisce l'URL XMLTV per l'EPG completo
  Future<String?> getXmltv() async {
    final r = await _dio.get('$_base&action=get_xmltv_url');
    final data = r.data as Map<String, dynamic>;
    return data['url'] as String?;
  }

  // ── Catchup ──────────────────────────────────────────────

  /// Costruisce URL catchup per un orario specifico
  String catchupUrl(String streamId, DateTime start, DateTime end) {
    final utc = start.millisecondsSinceEpoch ~/ 1000;
    final lutc = end.millisecondsSinceEpoch ~/ 1000;
    return '${playlist.serverUrl}/timeshift/${playlist.username}/${playlist.password}/$lutc/$utc/$streamId.ts';
  }
}
