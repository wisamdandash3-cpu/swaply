import 'package:supabase_flutter/supabase_flutter.dart';

/// نتيجة أغنية من Spotify Search API
class SpotifyTrack {
  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.url,
    required this.artist,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String url;
  final String artist;
  final String? imageUrl;

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    return SpotifyTrack(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

/// خدمة بحث Spotify عبر Supabase Edge Function
class SpotifySearchService {
  SpotifySearchService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _functionName = 'spotify-search';

  /// يبحث عن الأغاني في Spotify ويعيد قائمة النتائج.
  /// يرمي [SpotifySearchException] عند فشل الطلب أو الـ API.
  Future<List<SpotifyTrack>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    try {
      final res = await _client.functions.invoke(
        _functionName,
        body: {'query': q},
      );

    if (res.status != 200) {
      final msg = _extractErrorMessage(res.data);
      throw SpotifySearchException(msg ?? 'Search failed');
    }

    final data = res.data;
    if (data is! Map) throw SpotifySearchException('Invalid response');

    final raw = data['tracks'];
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((e) => SpotifyTrack.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    } catch (e) {
      if (e is SpotifySearchException) rethrow;
      throw SpotifySearchException(e.toString());
    }
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return null;
  }
}

/// بيانات أغنية مختارة (من البحث أو لصق الرابط)
class SpotifyTrackData {
  const SpotifyTrackData({
    required this.url,
    this.imageUrl,
    this.name,
    this.artist,
  });

  final String url;
  final String? imageUrl;
  final String? name;
  final String? artist;

  /// استخراج Track ID من رابط Spotify
  static String? extractTrackId(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final path = uri.path;
      if (path.contains('/track/')) {
        final parts = path.split('/track/');
        if (parts.length >= 2) {
          final id = parts[1].split('/').first.split('?').first;
          return id.isNotEmpty ? id : null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

/// استثناء عند فشل بحث Spotify
class SpotifySearchException implements Exception {
  SpotifySearchException(this.message);
  final String message;
  @override
  String toString() => message;
}
