import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme.dart';
import '../../data/models/playlist.dart';
import '../providers/channel_provider.dart';

class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box<PlaylistSource>('playlists');

    return Scaffold(
      appBar: AppBar(title: const Text('Le mie Playlist')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<PlaylistSource> b, _) {
          final playlists = b.values.toList();
          if (playlists.isEmpty) {
            return _EmptyState(onAdd: _showAddDialog);
          }
          return ListView.separated(
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final pl = playlists[i];
              return ListTile(
                leading: Icon(
                  pl.type == PlaylistType.xtream
                      ? Icons.api
                      : Icons.playlist_play,
                  color: pl.enabled ? AppTheme.accent : AppTheme.onSurface,
                ),
                title: Text(pl.name),
                subtitle: Text(
                  pl.type == PlaylistType.xtream
                      ? pl.serverUrl ?? ''
                      : pl.m3uUrl ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: pl.enabled,
                      onChanged: (v) {
                        pl.enabled = v;
                        pl.save();
                        ref.invalidate(channelsProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(pl),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
      ),
    );
  }

  void _confirmDelete(PlaylistSource pl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elimina playlist'),
        content: Text('Eliminare "${pl.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () {
              pl.delete();
              ref.invalidate(channelsProvider);
              Navigator.pop(context);
            },
            child: const Text('Elimina',
                style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddPlaylistSheet(
        onSave: (pl) {
          final box = Hive.box<PlaylistSource>('playlists');
          box.add(pl);
          ref.invalidate(channelsProvider);
        },
      ),
    );
  }
}

class _AddPlaylistSheet extends StatefulWidget {
  final Function(PlaylistSource) onSave;
  const _AddPlaylistSheet({required this.onSave});

  @override
  State<_AddPlaylistSheet> createState() => _AddPlaylistSheetState();
}

class _AddPlaylistSheetState extends State<_AddPlaylistSheet> {
  PlaylistType _type = PlaylistType.m3u;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _m3uUrlCtrl = TextEditingController();
  final _serverCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _epgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aggiungi playlist',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Tipo
              SegmentedButton<PlaylistType>(
                segments: const [
                  ButtonSegment(
                      value: PlaylistType.m3u, label: Text('M3U/M3U8')),
                  ButtonSegment(
                      value: PlaylistType.xtream, label: Text('Xtream Codes')),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome playlist'),
                validator: (v) =>
                    v?.isEmpty == true ? 'Inserisci un nome' : null,
              ),
              const SizedBox(height: 12),

              if (_type == PlaylistType.m3u) ...[
                TextFormField(
                  controller: _m3uUrlCtrl,
                  decoration:
                      const InputDecoration(labelText: 'URL M3U/M3U8'),
                  keyboardType: TextInputType.url,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Inserisci l\'URL' : null,
                ),
              ] else ...[
                TextFormField(
                  controller: _serverCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Server URL (es: http://server:8080)'),
                  keyboardType: TextInputType.url,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Inserisci il server' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) =>
                      v?.isEmpty == true ? 'Inserisci l\'username' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) =>
                      v?.isEmpty == true ? 'Inserisci la password' : null,
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _epgCtrl,
                decoration: const InputDecoration(
                    labelText: 'URL EPG XMLTV (opzionale)'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final pl = PlaylistSource()
      ..id = const Uuid().v4()
      ..name = _nameCtrl.text.trim()
      ..type = _type
      ..m3uUrl = _type == PlaylistType.m3u ? _m3uUrlCtrl.text.trim() : null
      ..serverUrl =
          _type == PlaylistType.xtream ? _serverCtrl.text.trim() : null
      ..username =
          _type == PlaylistType.xtream ? _userCtrl.text.trim() : null
      ..password =
          _type == PlaylistType.xtream ? _passCtrl.text.trim() : null
      ..epgUrl =
          _epgCtrl.text.trim().isNotEmpty ? _epgCtrl.text.trim() : null
      ..enabled = true;

    widget.onSave(pl);
    Navigator.pop(context);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.playlist_add, size: 80, color: AppTheme.onSurface),
          const SizedBox(height: 16),
          const Text('Nessuna playlist aggiunta',
              style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Aggiungi una lista M3U o Xtream Codes',
              style: TextStyle(color: AppTheme.onSurface)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi playlist'),
          ),
        ],
      ),
    );
  }
}
