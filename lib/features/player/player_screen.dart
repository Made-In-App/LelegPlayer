import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/epg_program.dart';
import '../providers/channel_provider.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String streamUrl;
  final String title;
  final String? channelId;

  const PlayerScreen({
    super.key,
    required this.streamUrl,
    required this.title,
    this.channelId,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _play(widget.streamUrl);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _play(String url) {
    _player.open(Media(url));
  }

  EPGProgram? _getNowPlaying() {
    if (widget.channelId == null) return null;
    final epg = ref.read(currentEpgProvider);
    return epg[widget.channelId]?.where((p) => p.isNow).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = _getNowPlaying();

    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              context.pop();
            } else if (event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.mediaPlayPause) {
              _player.playOrPause();
            }
          }
        },
        child: GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            children: [
              // ── Video ──────────────────────────────────────
              Center(
                child: Video(
                  controller: _controller,
                  controls: NoVideoControls,
                ),
              ),

              // ── Overlay controlli ──────────────────────────
              if (_showControls)
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _ControlsOverlay(
                    player: _player,
                    title: widget.title,
                    nowPlaying: nowPlaying,
                    channelId: widget.channelId,
                    onBack: () => context.pop(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final Player player;
  final String title;
  final EPGProgram? nowPlaying;
  final String? channelId;
  final VoidCallback onBack;

  const _ControlsOverlay({
    required this.player,
    required this.title,
    this.nowPlaying,
    this.channelId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000),
            Colors.transparent,
            Colors.transparent,
            Color(0xCC000000),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        children: [
          // ── Top bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      if (nowPlaying != null)
                        Text(
                          nowPlaying!.title,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // ── Bottom bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (nowPlaying != null) ...[
                  LinearProgressIndicator(
                    value: nowPlaying!.progress,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(nowPlaying!.start),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _formatTime(nowPlaying!.end),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StreamBuilder(
                      stream: player.stream.playing,
                      builder: (context, snapshot) {
                        final playing = snapshot.data ?? false;
                        return IconButton(
                          iconSize: 56,
                          icon: Icon(
                            playing ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.white,
                          ),
                          onPressed: player.playOrPause,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
