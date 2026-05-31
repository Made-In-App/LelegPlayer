import 'package:hive_flutter/hive_flutter.dart';

part 'playlist.g.dart';

enum PlaylistType { m3u, xtream }

@HiveType(typeId: 0)
class PlaylistSource extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int typeIndex; // PlaylistType.index

  // M3U fields
  @HiveField(3)
  String? m3uUrl;

  // Xtream fields
  @HiveField(4)
  String? serverUrl;

  @HiveField(5)
  String? username;

  @HiveField(6)
  String? password;

  // EPG
  @HiveField(7)
  String? epgUrl;

  @HiveField(8)
  DateTime? lastSynced;

  @HiveField(9)
  bool enabled = true;

  PlaylistType get type => PlaylistType.values[typeIndex];
  set type(PlaylistType t) => typeIndex = t.index;

  /// Costruisce l'URL base Xtream Codes
  String get xtreamBaseUrl => '$serverUrl/player_api.php?username=$username&password=$password';

  /// URL stream live Xtream
  String xtreamLiveUrl(int streamId, {String ext = 'ts'}) =>
      '$serverUrl/live/$username/$password/$streamId.$ext';

  /// URL stream VOD Xtream
  String xtreamVodUrl(int streamId, String ext) =>
      '$serverUrl/movie/$username/$password/$streamId.$ext';
}
