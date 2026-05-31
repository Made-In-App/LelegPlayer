class Channel {
  final String id;
  final String name;
  final String? logo;
  final String streamUrl;
  final String? group;
  final String? epgId;        // tvg-id per matching EPG
  final bool hasCatchup;
  final int? catchupDays;
  final String? playlistId;   // quale playlist

  const Channel({
    required this.id,
    required this.name,
    this.logo,
    required this.streamUrl,
    this.group,
    this.epgId,
    this.hasCatchup = false,
    this.catchupDays,
    this.playlistId,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? logo,
    String? streamUrl,
    String? group,
    String? epgId,
    bool? hasCatchup,
    int? catchupDays,
    String? playlistId,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      streamUrl: streamUrl ?? this.streamUrl,
      group: group ?? this.group,
      epgId: epgId ?? this.epgId,
      hasCatchup: hasCatchup ?? this.hasCatchup,
      catchupDays: catchupDays ?? this.catchupDays,
      playlistId: playlistId ?? this.playlistId,
    );
  }
}
