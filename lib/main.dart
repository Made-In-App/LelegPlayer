import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'app.dart';
import 'data/models/playlist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(PlaylistSourceAdapter());
  await Hive.openBox<PlaylistSource>('playlists');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: IPTVApp()));
}
