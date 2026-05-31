import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/epg_program.dart';
import '../providers/channel_provider.dart';

class EpgScreen extends ConsumerStatefulWidget {
  const EpgScreen({super.key});

  @override
  ConsumerState<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends ConsumerState<EpgScreen> {
  final _scrollController = ScrollController();
  late DateTime _visibleStart;
  static const double _channelColWidth = 160;
  static const double _rowHeight = 72;
  static const double _minuteWidth = 4.0; // pixel per minuto

  @override
  void initState() {
    super.initState();
    // Mostra da 2 ore fa
    _visibleStart = DateTime.now().subtract(const Duration(hours: 2));
    // Scroll al "now"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(
          const Duration(hours: 2).inMinutes * _minuteWidth - 20);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final epg = ref.watch(currentEpgProvider);

    return channelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (channels) {
        if (channels.isEmpty) {
          return const Center(child: Text('Nessun canale. Aggiungi una playlist.'));
        }

        final windowDuration = const Duration(hours: 6);
        final visibleEnd = _visibleStart.add(windowDuration);

        return Column(
          children: [
            // ── Timeline header ──────────────────────────────
            Row(
              children: [
                SizedBox(width: _channelColWidth),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: _TimelineHeader(
                      start: _visibleStart,
                      end: visibleEnd,
                      minuteWidth: _minuteWidth,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),

            // ── EPG grid ─────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  // Colonna canali (fissa)
                  SizedBox(
                    width: _channelColWidth,
                    child: ListView.separated(
                      itemCount: channels.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, thickness: 1),
                      itemBuilder: (context, i) {
                        final ch = channels[i];
                        return SizedBox(
                          height: _rowHeight,
                          child: _ChannelCell(channel: ch),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Griglia programmi (scrollabile)
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width:
                            windowDuration.inMinutes * _minuteWidth,
                        child: ListView.separated(
                          itemCount: channels.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, thickness: 1),
                          itemBuilder: (context, i) {
                            final ch = channels[i];
                            final epgId = ch.epgId ?? ch.id;
                            final programs = epg[epgId] ?? [];
                            final visible = programs
                                .where((p) =>
                                    p.end.isAfter(_visibleStart) &&
                                    p.start.isBefore(visibleEnd))
                                .toList();

                            return SizedBox(
                              height: _rowHeight,
                              child: Stack(
                                children: visible.map((prog) {
                                  final left = prog.start
                                              .difference(_visibleStart)
                                              .inMinutes *
                                          _minuteWidth;
                                  final width = prog.duration.inMinutes *
                                      _minuteWidth;
                                  return Positioned(
                                    left: left.clamp(0.0, double.infinity),
                                    top: 4,
                                    bottom: 4,
                                    width: width.clamp(0.0, double.infinity),
                                    child: _ProgramCell(
                                      program: prog,
                                      onTap: prog.hasCatchup
                                          ? () => context.go('/player',
                                              extra: {
                                                'url': ch.streamUrl,
                                                'title': prog.title,
                                                'channelId': epgId,
                                              })
                                          : prog.isNow
                                              ? () => context.go('/player',
                                                  extra: {
                                                    'url': ch.streamUrl,
                                                    'title': ch.name,
                                                    'channelId': epgId,
                                                  })
                                              : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                      ),
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

class _TimelineHeader extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final double minuteWidth;

  const _TimelineHeader({
    required this.start,
    required this.end,
    required this.minuteWidth,
  });

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[];
    var t = DateTime(start.year, start.month, start.day, start.hour);
    if (t.isBefore(start)) t = t.add(const Duration(hours: 1));

    while (t.isBefore(end)) {
      final left = t.difference(start).inMinutes * minuteWidth;
      slots.add(Positioned(
        left: left,
        child: Text(
          '${t.hour.toString().padLeft(2, '0')}:00',
          style: const TextStyle(fontSize: 11, color: AppTheme.onSurface),
        ),
      ));
      t = t.add(const Duration(hours: 1));
    }

    return SizedBox(
      height: 24,
      width: end.difference(start).inMinutes * minuteWidth,
      child: Stack(children: slots),
    );
  }
}

class _ChannelCell extends StatelessWidget {
  final dynamic channel;
  const _ChannelCell({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        channel.name,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}

class _ProgramCell extends StatelessWidget {
  final EPGProgram program;
  final VoidCallback? onTap;

  const _ProgramCell({required this.program, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    if (program.isNow) {
      bgColor = AppTheme.epgNow;
    } else if (program.isPast) {
      bgColor = AppTheme.epgPast;
    } else {
      bgColor = AppTheme.surface;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: program.isNow
              ? Border.all(color: AppTheme.accent, width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              program.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              '${_fmt(program.start)} - ${_fmt(program.end)}',
              style: const TextStyle(fontSize: 10, color: AppTheme.onSurface),
            ),
            if (program.isNow)
              Expanded(
                child: LinearProgressIndicator(
                  value: program.progress,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.accent),
                  minHeight: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
