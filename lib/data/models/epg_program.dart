class EPGProgram {
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  final String? category;
  final String? icon;
  final bool hasCatchup;

  const EPGProgram({
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
    this.category,
    this.icon,
    this.hasCatchup = false,
  });

  Duration get duration => end.difference(start);

  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool get isPast => DateTime.now().isAfter(end);

  /// Percentuale completamento (0.0 - 1.0) se in corso
  double get progress {
    if (!isNow) return isPast ? 1.0 : 0.0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return elapsed / duration.inSeconds;
  }
}
