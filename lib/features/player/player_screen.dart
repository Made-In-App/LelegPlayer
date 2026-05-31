import 'dart:async';
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

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final Player _player;
  late final VideoController _controller;
  late final AnimationController _fadeAnim;

  bool _showControls = true;
  Timer? _hideTimer;
  bool _isLive = true; // true = stream live, false = VOD

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );

    _play(widget.streamUrl);
    _detectLive(widget.streamUrl);
    _scheduleHide();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeAnim.dispose();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _play(String url) => _player.open(Media(url));

  void _detectLive(String url) {
    final u = url.toLowerCase();
    _isLive = !u.endsWith('.mkv') && !u.endsWith('.mp4') &&
        !u.endsWith('.avi') && !u.endsWith('.mov') &&
        !u.contains('/movie/');
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showControls = false);
        _fadeAnim.reverse();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _fadeAnim.forward();
      _scheduleHide();
    } else {
      _fadeAnim.reverse();
    }
  }

  void _showControlsTemporarily() {
    if (!_showControls) {
      setState(() => _showControls = true);
      _fadeAnim.forward();
    }
    _scheduleHide();
  }

  EPGProgram? _nowPlaying() {
    if (widget.channelId == null) return null;
    final epg = ref.read(currentEpgProvider);
    return epg[widget.channelId]?.where((p) => p.isNow).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) return;
          switch (event.logicalKey) {
            case LogicalKeyboardKey.escape:
            case LogicalKeyboardKey.goBack:
              _goBack();
            case LogicalKeyboardKey.space:
            case LogicalKeyboardKey.mediaPlayPause:
              _player.playOrPause();
              _showControlsTemporarily();
            case LogicalKeyboardKey.arrowLeft:
              if (!_isLive) {
                _player.seek((_player.state.position) -
                    const Duration(seconds: 10));
              }
              _showControlsTemporarily();
            case LogicalKeyboardKey.arrowRight:
              if (!_isLive) {
                _player.seek((_player.state.position) +
                    const Duration(seconds: 10));
              }
              _showControlsTemporarily();
            default:
              _showControlsTemporarily();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Video ──────────────────────────────────────────
              Video(
                controller: _controller,
                controls: NoVideoControls,
                fill: Colors.black,
              ),

              // ── Overlay con fade ───────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: _Overlay(
                  player: _player,
                  title: widget.title,
                  nowPlaying: _nowPlaying(),
                  isLive: _isLive,
                  onBack: _goBack,
                  onInteract: _showControlsTemporarily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overlay completo
// ─────────────────────────────────────────────────────────────

class _Overlay extends StatelessWidget {
  final Player player;
  final String title;
  final EPGProgram? nowPlaying;
  final bool isLive;
  final VoidCallback onBack;
  final VoidCallback onInteract;

  const _Overlay({
    required this.player,
    required this.title,
    this.nowPlaying,
    required this.isLive,
    required this.onBack,
    required this.onInteract,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradiente top
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0xDD000000), Colors.transparent],
            ),
          ),
        ),
        // Gradiente bottom
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xEE000000), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        Column(
          children: [
            // ── Top bar ────────────────────────────────────────
            _TopBar(title: title, nowPlaying: nowPlaying,
                isLive: isLive, onBack: onBack),

            const Spacer(),

            // ── Bottom bar ─────────────────────────────────────
            _BottomBar(player: player, nowPlaying: nowPlaying,
                isLive: isLive, onInteract: onInteract),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Top bar: back + titolo + badge LIVE + EPG attuale
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final EPGProgram? nowPlaying;
  final bool isLive;
  final VoidCallback onBack;

  const _TopBar({
    required this.title,
    this.nowPlaying,
    required this.isLive,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 22),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('● LIVE',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)]),
                    overflow: TextOverflow.ellipsis),
                if (nowPlaying != null)
                  Text(
                    '▶  ${nowPlaying!.title}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom bar: progress EPG + controlli
// ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Player player;
  final EPGProgram? nowPlaying;
  final bool isLive;
  final VoidCallback onInteract;

  const _BottomBar({
    required this.player,
    this.nowPlaying,
    required this.isLive,
    required this.onInteract,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── EPG progress bar ───────────────────────────────
          if (nowPlaying != null) ...[
            Row(
              children: [
                Text(_fmt(nowPlaying!.start),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: nowPlaying!.progress,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.accent),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ),
                Text(_fmt(nowPlaying!.end),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              nowPlaying!.title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],

          // ── VOD seek bar ───────────────────────────────────
          if (!isLive)
            StreamBuilder(
              stream: player.stream.position,
              builder: (context, posSnap) {
                return StreamBuilder(
                  stream: player.stream.duration,
                  builder: (context, durSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final dur = durSnap.data ?? Duration.zero;
                    final progress =
                        dur.inMilliseconds > 0
                            ? pos.inMilliseconds / dur.inMilliseconds
                            : 0.0;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppTheme.accent,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: SliderComponentShape.noOverlay,
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: progress.clamp(0.0, 1.0),
                            onChanged: (v) {
                              onInteract();
                              player.seek(Duration(
                                  milliseconds:
                                      (v * dur.inMilliseconds).round()));
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmtDur(pos),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                            Text(_fmtDur(dur),
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),

          const SizedBox(height: 8),

          // ── Pulsanti centrali ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind (solo VOD)
              if (!isLive)
                _CtrlBtn(
                  icon: Icons.replay_10,
                  size: 32,
                  onTap: () {
                    onInteract();
                    player.seek(
                        player.state.position - const Duration(seconds: 10));
                  },
                ),

              const SizedBox(width: 8),

              // Play / Pause
              StreamBuilder(
                stream: player.stream.playing,
                builder: (context, snap) {
                  final playing = snap.data ?? true;
                  return _CtrlBtn(
                    icon: playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 64,
                    onTap: () {
                      onInteract();
                      player.playOrPause();
                    },
                  );
                },
              ),

              const SizedBox(width: 8),

              // Forward (solo VOD) / Ricarica (live)
              if (!isLive)
                _CtrlBtn(
                  icon: Icons.forward_10,
                  size: 32,
                  onTap: () {
                    onInteract();
                    player.seek(
                        player.state.position + const Duration(seconds: 10));
                  },
                )
              else
                _CtrlBtn(
                  icon: Icons.refresh,
                  size: 32,
                  tooltip: 'Ricarica stream',
                  onTap: () {
                    onInteract();
                    player.open(Media(player.state.playlist.medias.first.uri));
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final String? tooltip;

  const _CtrlBtn({
    required this.icon,
    required this.size,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      borderRadius: BorderRadius.circular(size),
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size,
          shadows: const [Shadow(blurRadius: 8, color: Colors.black54)]),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}
