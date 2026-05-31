import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/epg_program.dart';
import '../parsers/xmltv_parser.dart';

/// Provider globale EPG: channelId → lista programmi
final epgProvider = StateProvider<Map<String, List<EPGProgram>>>((ref) => {});

class EpgService {
  final Dio _dio = Dio();

  /// Scarica e parsa un file XMLTV (supporta gzip)
  Future<Map<String, List<EPGProgram>>> fetchAndParse(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data!;
    String xmlContent;

    // Prova a decomprimere gzip
    try {
      xmlContent = utf8.decode(GZipCodec().decode(bytes));
    } catch (_) {
      xmlContent = utf8.decode(bytes);
    }

    return XMLTVParser.parse(xmlContent);
  }

  /// Trova il programma in corso per un channelId
  EPGProgram? getCurrentProgram(
      Map<String, List<EPGProgram>> epg, String channelId) {
    final programs = epg[channelId];
    if (programs == null || programs.isEmpty) return null;
    return programs.where((p) => p.isNow).firstOrNull;
  }

  /// Trova il prossimo programma
  EPGProgram? getNextProgram(
      Map<String, List<EPGProgram>> epg, String channelId) {
    final programs = epg[channelId];
    if (programs == null || programs.isEmpty) return null;
    final now = DateTime.now();
    return programs.where((p) => p.start.isAfter(now)).firstOrNull;
  }

  /// Programmi in un range orario per la EPG grid
  List<EPGProgram> getProgramsInRange(
    Map<String, List<EPGProgram>> epg,
    String channelId,
    DateTime from,
    DateTime to,
  ) {
    final programs = epg[channelId];
    if (programs == null) return [];
    return programs
        .where((p) => p.end.isAfter(from) && p.start.isBefore(to))
        .toList();
  }
}
