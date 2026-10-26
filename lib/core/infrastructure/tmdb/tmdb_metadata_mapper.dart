import 'package:mochi_player/core/domain/media/models.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_image_url.dart';
import 'package:mochi_player/core/infrastructure/tmdb/tmdb_season_result.dart';

class TmdbMetadataMapper {
  const TmdbMetadataMapper();

  Movie movie(Map<String, dynamic> data) {
    return Movie(
      tmdbId: data['id'].toString(),
      title: data['title'] ?? '',
      originalTitle: data['original_title'],
      releaseYear: _year(data['release_date']),
      releaseDate: _date(data['release_date']),
      posterUrl: TmdbImageUrl.poster(data['poster_path']),
      backdropUrl: TmdbImageUrl.backdrop(data['backdrop_path']),
      overview: data['overview'],
      certification: _movieCertification(data['release_dates']),
      rating: (data['vote_average'] as num? ?? 0.0).toDouble(),
      genres: _genres(data['genres']),
      cast: _cast(data['credits']),
      logoUrl: _logoUrl(data['images']),
    );
  }

  TVShow tvShow(Map<String, dynamic> data) {
    return TVShow(
      tmdbId: data['id'].toString(),
      title: data['name'] ?? '',
      originalTitle: data['original_name'],
      releaseYear: _year(data['first_air_date']),
      firstAirDate: _date(data['first_air_date']),
      posterUrl: TmdbImageUrl.poster(data['poster_path']),
      backdropUrl: TmdbImageUrl.backdrop(data['backdrop_path']),
      overview: data['overview'],
      certification: _tvCertification(data['content_ratings']),
      rating: (data['vote_average'] as num? ?? 0.0).toDouble(),
      genres: _genres(data['genres']),
      cast: _cast(data['credits']),
      logoUrl: _logoUrl(data['images']),
      status: data['status'],
      numberOfSeasons: data['number_of_seasons'],
      numberOfEpisodes: data['number_of_episodes'],
    );
  }

  TmdbSeasonResult season(Map<String, dynamic> data, String showTmdbId, int seasonNumber) {
    final episodeData = (data['episodes'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
    final metadata = Season(
      tvShowTmdbId: showTmdbId,
      seasonNumber: seasonNumber,
      title: data['name'] ?? '第 $seasonNumber 季',
      posterUrl: TmdbImageUrl.poster(data['poster_path']),
      overview: data['overview'],
      numberOfEpisodes: episodeData.length,
    );
    return TmdbSeasonResult(
      season: metadata,
      episodes: episodeData.map((episode) => _episode(episode, showTmdbId, seasonNumber)).toList(),
    );
  }

  TrendingItem trending(Map<String, dynamic> data, {bool? forceMovie}) {
    final isMovie = forceMovie ?? data['media_type'] == 'movie';
    return TrendingItem(
      tmdbId: data['id'].toString(),
      title: isMovie ? (data['title'] ?? '') : (data['name'] ?? ''),
      posterUrl: TmdbImageUrl.poster(data['poster_path']),
      backdropUrl: TmdbImageUrl.backdrop(data['backdrop_path']),
      overview: data['overview'],
      rating: (data['vote_average'] as num? ?? 0.0).toDouble(),
      releaseYear: _year(isMovie ? data['release_date'] : data['first_air_date']),
      genres: _genreNames(data['genre_ids']),
      isMovie: isMovie,
    );
  }

  Episode _episode(Map<String, dynamic> data, String showTmdbId, int seasonNumber) {
    final episodeNumber = data['episode_number'] as int;
    return Episode(
      tvShowTmdbId: showTmdbId,
      seasonNumber: seasonNumber,
      tmdbId: data['id']?.toString(),
      episodeNumber: episodeNumber,
      title: data['name'] ?? 'Episode $episodeNumber',
      airDate: _date(data['air_date']),
      overview: data['overview'],
      stillUrl: TmdbImageUrl.backdrop(data['still_path']),
      guestStars: _artists(data['guest_stars'], limit: 5),
    );
  }

  int? _year(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value.split('-').first);
  }

  DateTime? _date(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  List<String> _genres(List<dynamic>? values) => values?.map((genre) => genre['name'].toString()).toList() ?? const [];

  List<Artist> _cast(Map<String, dynamic>? credits) => _artists(credits?['cast'] as List?, limit: 10);

  List<Artist> _artists(List<dynamic>? values, {required int limit}) {
    if (values == null) return [];
    return values.take(limit).map((value) {
      return Artist(
        tmdbId: value['id']?.toString(),
        name: value['name'] ?? '未知',
        character: value['character'],
        profileUrl: TmdbImageUrl.profile(value['profile_path']),
      );
    }).toList();
  }

  String? _logoUrl(Map<String, dynamic>? images) {
    final logos = images?['logos'] as List?;
    if (logos == null || logos.isEmpty) return null;
    for (final language in ['zh', 'en', null]) {
      for (final logo in logos) {
        if (logo['iso_639_1'] == language && logo['file_path'] != null) {
          return TmdbImageUrl.logo(logo['file_path']);
        }
      }
    }
    return TmdbImageUrl.logo(logos.first['file_path']);
  }

  String? _movieCertification(Map<String, dynamic>? releaseDates) {
    final results = releaseDates?['results'] as List?;
    if (results == null) return null;
    for (final country in ['US', 'CN']) {
      for (final item in results) {
        if (item['iso_3166_1'] != country) continue;
        for (final date in item['release_dates'] as List? ?? const []) {
          final value = date['certification']?.toString() ?? '';
          if (value.isNotEmpty) return value;
        }
      }
    }
    return null;
  }

  String? _tvCertification(Map<String, dynamic>? ratings) {
    final results = ratings?['results'] as List?;
    if (results == null) return null;
    for (final country in ['US', 'CN']) {
      for (final item in results) {
        if (item['iso_3166_1'] != country) continue;
        final value = item['rating']?.toString() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  List<String> _genreNames(List<dynamic>? ids) {
    if (ids == null) return const [];
    const names = {
      28: 'Action',
      12: 'Adventure',
      16: 'Animation',
      35: 'Comedy',
      80: 'Crime',
      99: 'Documentary',
      18: 'Drama',
      10751: 'Family',
      14: 'Fantasy',
      36: 'History',
      27: 'Horror',
      10402: 'Music',
      9648: 'Mystery',
      10749: 'Romance',
      878: 'Sci-Fi',
      10770: 'TV Movie',
      53: 'Thriller',
      10752: 'War',
      37: 'Western',
      10759: 'Action',
      10762: 'Kids',
      10763: 'News',
      10764: 'Reality',
      10765: 'Sci-Fi',
      10766: 'Soap',
      10767: 'Talk',
      10768: 'Politics',
    };
    return ids.take(2).map((id) => names[id] ?? '').where((name) => name.isNotEmpty).toList();
  }
}
