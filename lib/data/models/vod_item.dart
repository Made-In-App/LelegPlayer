enum VodType { movie, series, episode }

class VodItem {
  final String id;
  final String name;
  final String? cover;
  final String? plot;
  final String? genre;
  final String? year;
  final String? rating;
  final VodType type;
  final String? streamUrl;
  final String? containerExtension;
  final String? seriesId;
  final int? seasonNum;
  final int? episodeNum;
  final String? playlistId;

  const VodItem({
    required this.id,
    required this.name,
    this.cover,
    this.plot,
    this.genre,
    this.year,
    this.rating,
    required this.type,
    this.streamUrl,
    this.containerExtension,
    this.seriesId,
    this.seasonNum,
    this.episodeNum,
    this.playlistId,
  });
}
