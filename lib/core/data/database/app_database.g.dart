// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TVShowsTable extends TVShows with TableInfo<$TVShowsTable, TVShowDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TVShowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta('originalTitle');
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta('releaseYear');
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstAirDateMeta = const VerificationMeta('firstAirDate');
  @override
  late final GeneratedColumn<DateTime> firstAirDate = GeneratedColumn<DateTime>(
    'first_air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationMeta = const VerificationMeta('certification');
  @override
  late final GeneratedColumn<String> certification = GeneratedColumn<String>(
    'certification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfSeasonsMeta = const VerificationMeta('numberOfSeasons');
  @override
  late final GeneratedColumn<int> numberOfSeasons = GeneratedColumn<int>(
    'number_of_seasons',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfEpisodesMeta = const VerificationMeta('numberOfEpisodes');
  @override
  late final GeneratedColumn<int> numberOfEpisodes = GeneratedColumn<int>(
    'number_of_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    firstAirDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
    status,
    numberOfSeasons,
    numberOfEpisodes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 't_v_shows';
  @override
  VerificationContext validateIntegrity(Insertable<TVShowDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(data['original_title']!, _originalTitleMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(_releaseYearMeta, releaseYear.isAcceptableOrUnknown(data['release_year']!, _releaseYearMeta));
    }
    if (data.containsKey('first_air_date')) {
      context.handle(_firstAirDateMeta, firstAirDate.isAcceptableOrUnknown(data['first_air_date']!, _firstAirDateMeta));
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(_backdropUrlMeta, backdropUrl.isAcceptableOrUnknown(data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta, logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('certification')) {
      context.handle(
        _certificationMeta,
        certification.isAcceptableOrUnknown(data['certification']!, _certificationMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('genres')) {
      context.handle(_genresMeta, genres.isAcceptableOrUnknown(data['genres']!, _genresMeta));
    } else if (isInserting) {
      context.missing(_genresMeta);
    }
    if (data.containsKey('cast')) {
      context.handle(_castMeta, cast.isAcceptableOrUnknown(data['cast']!, _castMeta));
    } else if (isInserting) {
      context.missing(_castMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('number_of_seasons')) {
      context.handle(
        _numberOfSeasonsMeta,
        numberOfSeasons.isAcceptableOrUnknown(data['number_of_seasons']!, _numberOfSeasonsMeta),
      );
    }
    if (data.containsKey('number_of_episodes')) {
      context.handle(
        _numberOfEpisodesMeta,
        numberOfEpisodes.isAcceptableOrUnknown(data['number_of_episodes']!, _numberOfEpisodesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  TVShowDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TVShowDO(
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}original_title']),
      releaseYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}release_year']),
      firstAirDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}first_air_date']),
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      backdropUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      logoUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      certification: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}certification']),
      rating: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      genres: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}genres'])!,
      cast: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cast'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status']),
      numberOfSeasons: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}number_of_seasons']),
      numberOfEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_episodes'],
      ),
    );
  }

  @override
  $TVShowsTable createAlias(String alias) {
    return $TVShowsTable(attachedDatabase, alias);
  }
}

class TVShowDO extends DataClass implements Insertable<TVShowDO> {
  final String tmdbId;
  final String title;
  final String? originalTitle;
  final int? releaseYear;
  final DateTime? firstAirDate;
  final String? posterUrl;
  final String? backdropUrl;
  final String? logoUrl;
  final String? overview;
  final String? certification;
  final double rating;
  final String genres;
  final String cast;
  final String? status;
  final int? numberOfSeasons;
  final int? numberOfEpisodes;
  const TVShowDO({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.releaseYear,
    this.firstAirDate,
    this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.overview,
    this.certification,
    required this.rating,
    required this.genres,
    required this.cast,
    this.status,
    this.numberOfSeasons,
    this.numberOfEpisodes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<String>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || firstAirDate != null) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || certification != null) {
      map['certification'] = Variable<String>(certification);
    }
    map['rating'] = Variable<double>(rating);
    map['genres'] = Variable<String>(genres);
    map['cast'] = Variable<String>(cast);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || numberOfSeasons != null) {
      map['number_of_seasons'] = Variable<int>(numberOfSeasons);
    }
    if (!nullToAbsent || numberOfEpisodes != null) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes);
    }
    return map;
  }

  TVShowsCompanion toCompanion(bool nullToAbsent) {
    return TVShowsCompanion(
      tmdbId: Value(tmdbId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent ? const Value.absent() : Value(originalTitle),
      releaseYear: releaseYear == null && nullToAbsent ? const Value.absent() : Value(releaseYear),
      firstAirDate: firstAirDate == null && nullToAbsent ? const Value.absent() : Value(firstAirDate),
      posterUrl: posterUrl == null && nullToAbsent ? const Value.absent() : Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent ? const Value.absent() : Value(backdropUrl),
      logoUrl: logoUrl == null && nullToAbsent ? const Value.absent() : Value(logoUrl),
      overview: overview == null && nullToAbsent ? const Value.absent() : Value(overview),
      certification: certification == null && nullToAbsent ? const Value.absent() : Value(certification),
      rating: Value(rating),
      genres: Value(genres),
      cast: Value(cast),
      status: status == null && nullToAbsent ? const Value.absent() : Value(status),
      numberOfSeasons: numberOfSeasons == null && nullToAbsent ? const Value.absent() : Value(numberOfSeasons),
      numberOfEpisodes: numberOfEpisodes == null && nullToAbsent ? const Value.absent() : Value(numberOfEpisodes),
    );
  }

  factory TVShowDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TVShowDO(
      tmdbId: serializer.fromJson<String>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      firstAirDate: serializer.fromJson<DateTime?>(json['firstAirDate']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      overview: serializer.fromJson<String?>(json['overview']),
      certification: serializer.fromJson<String?>(json['certification']),
      rating: serializer.fromJson<double>(json['rating']),
      genres: serializer.fromJson<String>(json['genres']),
      cast: serializer.fromJson<String>(json['cast']),
      status: serializer.fromJson<String?>(json['status']),
      numberOfSeasons: serializer.fromJson<int?>(json['numberOfSeasons']),
      numberOfEpisodes: serializer.fromJson<int?>(json['numberOfEpisodes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<String>(tmdbId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'firstAirDate': serializer.toJson<DateTime?>(firstAirDate),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'overview': serializer.toJson<String?>(overview),
      'certification': serializer.toJson<String?>(certification),
      'rating': serializer.toJson<double>(rating),
      'genres': serializer.toJson<String>(genres),
      'cast': serializer.toJson<String>(cast),
      'status': serializer.toJson<String?>(status),
      'numberOfSeasons': serializer.toJson<int?>(numberOfSeasons),
      'numberOfEpisodes': serializer.toJson<int?>(numberOfEpisodes),
    };
  }

  TVShowDO copyWith({
    String? tmdbId,
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    Value<DateTime?> firstAirDate = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    Value<String?> backdropUrl = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> certification = const Value.absent(),
    double? rating,
    String? genres,
    String? cast,
    Value<String?> status = const Value.absent(),
    Value<int?> numberOfSeasons = const Value.absent(),
    Value<int?> numberOfEpisodes = const Value.absent(),
  }) => TVShowDO(
    tmdbId: tmdbId ?? this.tmdbId,
    title: title ?? this.title,
    originalTitle: originalTitle.present ? originalTitle.value : this.originalTitle,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    firstAirDate: firstAirDate.present ? firstAirDate.value : this.firstAirDate,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    overview: overview.present ? overview.value : this.overview,
    certification: certification.present ? certification.value : this.certification,
    rating: rating ?? this.rating,
    genres: genres ?? this.genres,
    cast: cast ?? this.cast,
    status: status.present ? status.value : this.status,
    numberOfSeasons: numberOfSeasons.present ? numberOfSeasons.value : this.numberOfSeasons,
    numberOfEpisodes: numberOfEpisodes.present ? numberOfEpisodes.value : this.numberOfEpisodes,
  );
  TVShowDO copyWithCompanion(TVShowsCompanion data) {
    return TVShowDO(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present ? data.originalTitle.value : this.originalTitle,
      releaseYear: data.releaseYear.present ? data.releaseYear.value : this.releaseYear,
      firstAirDate: data.firstAirDate.present ? data.firstAirDate.value : this.firstAirDate,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl: data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      overview: data.overview.present ? data.overview.value : this.overview,
      certification: data.certification.present ? data.certification.value : this.certification,
      rating: data.rating.present ? data.rating.value : this.rating,
      genres: data.genres.present ? data.genres.value : this.genres,
      cast: data.cast.present ? data.cast.value : this.cast,
      status: data.status.present ? data.status.value : this.status,
      numberOfSeasons: data.numberOfSeasons.present ? data.numberOfSeasons.value : this.numberOfSeasons,
      numberOfEpisodes: data.numberOfEpisodes.present ? data.numberOfEpisodes.value : this.numberOfEpisodes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TVShowDO(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast, ')
          ..write('status: $status, ')
          ..write('numberOfSeasons: $numberOfSeasons, ')
          ..write('numberOfEpisodes: $numberOfEpisodes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    firstAirDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
    status,
    numberOfSeasons,
    numberOfEpisodes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TVShowDO &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.releaseYear == this.releaseYear &&
          other.firstAirDate == this.firstAirDate &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.logoUrl == this.logoUrl &&
          other.overview == this.overview &&
          other.certification == this.certification &&
          other.rating == this.rating &&
          other.genres == this.genres &&
          other.cast == this.cast &&
          other.status == this.status &&
          other.numberOfSeasons == this.numberOfSeasons &&
          other.numberOfEpisodes == this.numberOfEpisodes);
}

class TVShowsCompanion extends UpdateCompanion<TVShowDO> {
  final Value<String> tmdbId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> releaseYear;
  final Value<DateTime?> firstAirDate;
  final Value<String?> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> logoUrl;
  final Value<String?> overview;
  final Value<String?> certification;
  final Value<double> rating;
  final Value<String> genres;
  final Value<String> cast;
  final Value<String?> status;
  final Value<int?> numberOfSeasons;
  final Value<int?> numberOfEpisodes;
  final Value<int> rowid;
  const TVShowsCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    this.rating = const Value.absent(),
    this.genres = const Value.absent(),
    this.cast = const Value.absent(),
    this.status = const Value.absent(),
    this.numberOfSeasons = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TVShowsCompanion.insert({
    required String tmdbId,
    required String title,
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.firstAirDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    required double rating,
    required String genres,
    required String cast,
    this.status = const Value.absent(),
    this.numberOfSeasons = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       title = Value(title),
       rating = Value(rating),
       genres = Value(genres),
       cast = Value(cast);
  static Insertable<TVShowDO> custom({
    Expression<String>? tmdbId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? releaseYear,
    Expression<DateTime>? firstAirDate,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? logoUrl,
    Expression<String>? overview,
    Expression<String>? certification,
    Expression<double>? rating,
    Expression<String>? genres,
    Expression<String>? cast,
    Expression<String>? status,
    Expression<int>? numberOfSeasons,
    Expression<int>? numberOfEpisodes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (releaseYear != null) 'release_year': releaseYear,
      if (firstAirDate != null) 'first_air_date': firstAirDate,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (overview != null) 'overview': overview,
      if (certification != null) 'certification': certification,
      if (rating != null) 'rating': rating,
      if (genres != null) 'genres': genres,
      if (cast != null) 'cast': cast,
      if (status != null) 'status': status,
      if (numberOfSeasons != null) 'number_of_seasons': numberOfSeasons,
      if (numberOfEpisodes != null) 'number_of_episodes': numberOfEpisodes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TVShowsCompanion copyWith({
    Value<String>? tmdbId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? releaseYear,
    Value<DateTime?>? firstAirDate,
    Value<String?>? posterUrl,
    Value<String?>? backdropUrl,
    Value<String?>? logoUrl,
    Value<String?>? overview,
    Value<String?>? certification,
    Value<double>? rating,
    Value<String>? genres,
    Value<String>? cast,
    Value<String?>? status,
    Value<int?>? numberOfSeasons,
    Value<int?>? numberOfEpisodes,
    Value<int>? rowid,
  }) {
    return TVShowsCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      releaseYear: releaseYear ?? this.releaseYear,
      firstAirDate: firstAirDate ?? this.firstAirDate,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      certification: certification ?? this.certification,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      status: status ?? this.status,
      numberOfSeasons: numberOfSeasons ?? this.numberOfSeasons,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (firstAirDate.present) {
      map['first_air_date'] = Variable<DateTime>(firstAirDate.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (certification.present) {
      map['certification'] = Variable<String>(certification.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (numberOfSeasons.present) {
      map['number_of_seasons'] = Variable<int>(numberOfSeasons.value);
    }
    if (numberOfEpisodes.present) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TVShowsCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('firstAirDate: $firstAirDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast, ')
          ..write('status: $status, ')
          ..write('numberOfSeasons: $numberOfSeasons, ')
          ..write('numberOfEpisodes: $numberOfEpisodes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons with TableInfo<$SeasonsTable, SeasonDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tvShowTmdbIdMeta = const VerificationMeta('tvShowTmdbId');
  @override
  late final GeneratedColumn<String> tvShowTmdbId = GeneratedColumn<String>(
    'tv_show_tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES t_v_shows (tmdb_id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta('seasonNumber');
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberOfEpisodesMeta = const VerificationMeta('numberOfEpisodes');
  @override
  late final GeneratedColumn<int> numberOfEpisodes = GeneratedColumn<int>(
    'number_of_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tvShowTmdbId, seasonNumber, title, posterUrl, overview, numberOfEpisodes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(Insertable<SeasonDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tv_show_tmdb_id')) {
      context.handle(
        _tvShowTmdbIdMeta,
        tvShowTmdbId.isAcceptableOrUnknown(data['tv_show_tmdb_id']!, _tvShowTmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tvShowTmdbIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(_seasonNumberMeta, seasonNumber.isAcceptableOrUnknown(data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('number_of_episodes')) {
      context.handle(
        _numberOfEpisodesMeta,
        numberOfEpisodes.isAcceptableOrUnknown(data['number_of_episodes']!, _numberOfEpisodesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tvShowTmdbId, seasonNumber};
  @override
  SeasonDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonDO(
      tvShowTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tv_show_tmdb_id'])!,
      seasonNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      numberOfEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number_of_episodes'],
      ),
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class SeasonDO extends DataClass implements Insertable<SeasonDO> {
  final String tvShowTmdbId;
  final int seasonNumber;
  final String title;
  final String? posterUrl;
  final String? overview;
  final int? numberOfEpisodes;
  const SeasonDO({
    required this.tvShowTmdbId,
    required this.seasonNumber,
    required this.title,
    this.posterUrl,
    this.overview,
    this.numberOfEpisodes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId);
    map['season_number'] = Variable<int>(seasonNumber);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || numberOfEpisodes != null) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes);
    }
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      tvShowTmdbId: Value(tvShowTmdbId),
      seasonNumber: Value(seasonNumber),
      title: Value(title),
      posterUrl: posterUrl == null && nullToAbsent ? const Value.absent() : Value(posterUrl),
      overview: overview == null && nullToAbsent ? const Value.absent() : Value(overview),
      numberOfEpisodes: numberOfEpisodes == null && nullToAbsent ? const Value.absent() : Value(numberOfEpisodes),
    );
  }

  factory SeasonDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonDO(
      tvShowTmdbId: serializer.fromJson<String>(json['tvShowTmdbId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      overview: serializer.fromJson<String?>(json['overview']),
      numberOfEpisodes: serializer.fromJson<int?>(json['numberOfEpisodes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tvShowTmdbId': serializer.toJson<String>(tvShowTmdbId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'overview': serializer.toJson<String?>(overview),
      'numberOfEpisodes': serializer.toJson<int?>(numberOfEpisodes),
    };
  }

  SeasonDO copyWith({
    String? tvShowTmdbId,
    int? seasonNumber,
    String? title,
    Value<String?> posterUrl = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<int?> numberOfEpisodes = const Value.absent(),
  }) => SeasonDO(
    tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    title: title ?? this.title,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    overview: overview.present ? overview.value : this.overview,
    numberOfEpisodes: numberOfEpisodes.present ? numberOfEpisodes.value : this.numberOfEpisodes,
  );
  SeasonDO copyWithCompanion(SeasonsCompanion data) {
    return SeasonDO(
      tvShowTmdbId: data.tvShowTmdbId.present ? data.tvShowTmdbId.value : this.tvShowTmdbId,
      seasonNumber: data.seasonNumber.present ? data.seasonNumber.value : this.seasonNumber,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      overview: data.overview.present ? data.overview.value : this.overview,
      numberOfEpisodes: data.numberOfEpisodes.present ? data.numberOfEpisodes.value : this.numberOfEpisodes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonDO(')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('overview: $overview, ')
          ..write('numberOfEpisodes: $numberOfEpisodes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tvShowTmdbId, seasonNumber, title, posterUrl, overview, numberOfEpisodes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonDO &&
          other.tvShowTmdbId == this.tvShowTmdbId &&
          other.seasonNumber == this.seasonNumber &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.overview == this.overview &&
          other.numberOfEpisodes == this.numberOfEpisodes);
}

class SeasonsCompanion extends UpdateCompanion<SeasonDO> {
  final Value<String> tvShowTmdbId;
  final Value<int> seasonNumber;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<String?> overview;
  final Value<int?> numberOfEpisodes;
  final Value<int> rowid;
  const SeasonsCompanion({
    this.tvShowTmdbId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeasonsCompanion.insert({
    required String tvShowTmdbId,
    required int seasonNumber,
    required String title,
    this.posterUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.numberOfEpisodes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tvShowTmdbId = Value(tvShowTmdbId),
       seasonNumber = Value(seasonNumber),
       title = Value(title);
  static Insertable<SeasonDO> custom({
    Expression<String>? tvShowTmdbId,
    Expression<int>? seasonNumber,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? overview,
    Expression<int>? numberOfEpisodes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tvShowTmdbId != null) 'tv_show_tmdb_id': tvShowTmdbId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (overview != null) 'overview': overview,
      if (numberOfEpisodes != null) 'number_of_episodes': numberOfEpisodes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeasonsCompanion copyWith({
    Value<String>? tvShowTmdbId,
    Value<int>? seasonNumber,
    Value<String>? title,
    Value<String?>? posterUrl,
    Value<String?>? overview,
    Value<int?>? numberOfEpisodes,
    Value<int>? rowid,
  }) {
    return SeasonsCompanion(
      tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      numberOfEpisodes: numberOfEpisodes ?? this.numberOfEpisodes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tvShowTmdbId.present) {
      map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (numberOfEpisodes.present) {
      map['number_of_episodes'] = Variable<int>(numberOfEpisodes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('overview: $overview, ')
          ..write('numberOfEpisodes: $numberOfEpisodes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Episodes extends Table with TableInfo<Episodes, EpisodeDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Episodes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _episodeKeyMeta = const VerificationMeta('episodeKey');
  late final GeneratedColumn<String> episodeKey = GeneratedColumn<String>(
    'episode_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _tvShowTmdbIdMeta = const VerificationMeta('tvShowTmdbId');
  late final GeneratedColumn<String> tvShowTmdbId = GeneratedColumn<String>(
    'tv_show_tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta('seasonNumber');
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta('episodeNumber');
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _airDateMeta = const VerificationMeta('airDate');
  late final GeneratedColumn<DateTime> airDate = GeneratedColumn<DateTime>(
    'air_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _stillUrlMeta = const VerificationMeta('stillUrl');
  late final GeneratedColumn<String> stillUrl = GeneratedColumn<String>(
    'still_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _guestStarsMeta = const VerificationMeta('guestStars');
  late final GeneratedColumn<String> guestStars = GeneratedColumn<String>(
    'guest_stars',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    episodeKey,
    tvShowTmdbId,
    seasonNumber,
    tmdbId,
    episodeNumber,
    title,
    airDate,
    overview,
    stillUrl,
    guestStars,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(Insertable<EpisodeDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('episode_key')) {
      context.handle(_episodeKeyMeta, episodeKey.isAcceptableOrUnknown(data['episode_key']!, _episodeKeyMeta));
    } else if (isInserting) {
      context.missing(_episodeKeyMeta);
    }
    if (data.containsKey('tv_show_tmdb_id')) {
      context.handle(
        _tvShowTmdbIdMeta,
        tvShowTmdbId.isAcceptableOrUnknown(data['tv_show_tmdb_id']!, _tvShowTmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tvShowTmdbIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(_seasonNumberMeta, seasonNumber.isAcceptableOrUnknown(data['season_number']!, _seasonNumberMeta));
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(data['episode_number']!, _episodeNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('air_date')) {
      context.handle(_airDateMeta, airDate.isAcceptableOrUnknown(data['air_date']!, _airDateMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('still_url')) {
      context.handle(_stillUrlMeta, stillUrl.isAcceptableOrUnknown(data['still_url']!, _stillUrlMeta));
    }
    if (data.containsKey('guest_stars')) {
      context.handle(_guestStarsMeta, guestStars.isAcceptableOrUnknown(data['guest_stars']!, _guestStarsMeta));
    } else if (isInserting) {
      context.missing(_guestStarsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {episodeKey};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tvShowTmdbId, seasonNumber, episodeNumber},
    {episodeKey, tvShowTmdbId},
  ];
  @override
  EpisodeDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeDO(
      episodeKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}episode_key'])!,
      tvShowTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tv_show_tmdb_id'])!,
      seasonNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}season_number'])!,
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id']),
      episodeNumber: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}episode_number'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      airDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}air_date']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      stillUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}still_url']),
      guestStars: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}guest_stars'])!,
    );
  }

  @override
  Episodes createAlias(String alias) {
    return Episodes(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(tv_show_tmdb_id, season_number, episode_number)',
    'UNIQUE(episode_key, tv_show_tmdb_id)',
    'FOREIGN KEY(tv_show_tmdb_id, season_number)REFERENCES seasons(tv_show_tmdb_id, season_number)ON DELETE CASCADE',
    'CHECK(season_number >= 0 AND episode_number >= 0)',
    'CHECK(episode_key = tv_show_tmdb_id || \'_s\' || season_number || \'e\' || episode_number)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class EpisodeDO extends DataClass implements Insertable<EpisodeDO> {
  final String episodeKey;
  final String tvShowTmdbId;
  final int seasonNumber;
  final String? tmdbId;
  final int episodeNumber;
  final String title;
  final DateTime? airDate;
  final String? overview;
  final String? stillUrl;
  final String guestStars;
  const EpisodeDO({
    required this.episodeKey,
    required this.tvShowTmdbId,
    required this.seasonNumber,
    this.tmdbId,
    required this.episodeNumber,
    required this.title,
    this.airDate,
    this.overview,
    this.stillUrl,
    required this.guestStars,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['episode_key'] = Variable<String>(episodeKey);
    map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || tmdbId != null) {
      map['tmdb_id'] = Variable<String>(tmdbId);
    }
    map['episode_number'] = Variable<int>(episodeNumber);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || airDate != null) {
      map['air_date'] = Variable<DateTime>(airDate);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || stillUrl != null) {
      map['still_url'] = Variable<String>(stillUrl);
    }
    map['guest_stars'] = Variable<String>(guestStars);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      episodeKey: Value(episodeKey),
      tvShowTmdbId: Value(tvShowTmdbId),
      seasonNumber: Value(seasonNumber),
      tmdbId: tmdbId == null && nullToAbsent ? const Value.absent() : Value(tmdbId),
      episodeNumber: Value(episodeNumber),
      title: Value(title),
      airDate: airDate == null && nullToAbsent ? const Value.absent() : Value(airDate),
      overview: overview == null && nullToAbsent ? const Value.absent() : Value(overview),
      stillUrl: stillUrl == null && nullToAbsent ? const Value.absent() : Value(stillUrl),
      guestStars: Value(guestStars),
    );
  }

  factory EpisodeDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeDO(
      episodeKey: serializer.fromJson<String>(json['episode_key']),
      tvShowTmdbId: serializer.fromJson<String>(json['tv_show_tmdb_id']),
      seasonNumber: serializer.fromJson<int>(json['season_number']),
      tmdbId: serializer.fromJson<String?>(json['tmdb_id']),
      episodeNumber: serializer.fromJson<int>(json['episode_number']),
      title: serializer.fromJson<String>(json['title']),
      airDate: serializer.fromJson<DateTime?>(json['air_date']),
      overview: serializer.fromJson<String?>(json['overview']),
      stillUrl: serializer.fromJson<String?>(json['still_url']),
      guestStars: serializer.fromJson<String>(json['guest_stars']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'episode_key': serializer.toJson<String>(episodeKey),
      'tv_show_tmdb_id': serializer.toJson<String>(tvShowTmdbId),
      'season_number': serializer.toJson<int>(seasonNumber),
      'tmdb_id': serializer.toJson<String?>(tmdbId),
      'episode_number': serializer.toJson<int>(episodeNumber),
      'title': serializer.toJson<String>(title),
      'air_date': serializer.toJson<DateTime?>(airDate),
      'overview': serializer.toJson<String?>(overview),
      'still_url': serializer.toJson<String?>(stillUrl),
      'guest_stars': serializer.toJson<String>(guestStars),
    };
  }

  EpisodeDO copyWith({
    String? episodeKey,
    String? tvShowTmdbId,
    int? seasonNumber,
    Value<String?> tmdbId = const Value.absent(),
    int? episodeNumber,
    String? title,
    Value<DateTime?> airDate = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> stillUrl = const Value.absent(),
    String? guestStars,
  }) => EpisodeDO(
    episodeKey: episodeKey ?? this.episodeKey,
    tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    tmdbId: tmdbId.present ? tmdbId.value : this.tmdbId,
    episodeNumber: episodeNumber ?? this.episodeNumber,
    title: title ?? this.title,
    airDate: airDate.present ? airDate.value : this.airDate,
    overview: overview.present ? overview.value : this.overview,
    stillUrl: stillUrl.present ? stillUrl.value : this.stillUrl,
    guestStars: guestStars ?? this.guestStars,
  );
  EpisodeDO copyWithCompanion(EpisodesCompanion data) {
    return EpisodeDO(
      episodeKey: data.episodeKey.present ? data.episodeKey.value : this.episodeKey,
      tvShowTmdbId: data.tvShowTmdbId.present ? data.tvShowTmdbId.value : this.tvShowTmdbId,
      seasonNumber: data.seasonNumber.present ? data.seasonNumber.value : this.seasonNumber,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      episodeNumber: data.episodeNumber.present ? data.episodeNumber.value : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      airDate: data.airDate.present ? data.airDate.value : this.airDate,
      overview: data.overview.present ? data.overview.value : this.overview,
      stillUrl: data.stillUrl.present ? data.stillUrl.value : this.stillUrl,
      guestStars: data.guestStars.present ? data.guestStars.value : this.guestStars,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeDO(')
          ..write('episodeKey: $episodeKey, ')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('airDate: $airDate, ')
          ..write('overview: $overview, ')
          ..write('stillUrl: $stillUrl, ')
          ..write('guestStars: $guestStars')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    episodeKey,
    tvShowTmdbId,
    seasonNumber,
    tmdbId,
    episodeNumber,
    title,
    airDate,
    overview,
    stillUrl,
    guestStars,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeDO &&
          other.episodeKey == this.episodeKey &&
          other.tvShowTmdbId == this.tvShowTmdbId &&
          other.seasonNumber == this.seasonNumber &&
          other.tmdbId == this.tmdbId &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.airDate == this.airDate &&
          other.overview == this.overview &&
          other.stillUrl == this.stillUrl &&
          other.guestStars == this.guestStars);
}

class EpisodesCompanion extends UpdateCompanion<EpisodeDO> {
  final Value<String> episodeKey;
  final Value<String> tvShowTmdbId;
  final Value<int> seasonNumber;
  final Value<String?> tmdbId;
  final Value<int> episodeNumber;
  final Value<String> title;
  final Value<DateTime?> airDate;
  final Value<String?> overview;
  final Value<String?> stillUrl;
  final Value<String> guestStars;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.episodeKey = const Value.absent(),
    this.tvShowTmdbId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.airDate = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillUrl = const Value.absent(),
    this.guestStars = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String episodeKey,
    required String tvShowTmdbId,
    required int seasonNumber,
    this.tmdbId = const Value.absent(),
    required int episodeNumber,
    required String title,
    this.airDate = const Value.absent(),
    this.overview = const Value.absent(),
    this.stillUrl = const Value.absent(),
    required String guestStars,
    this.rowid = const Value.absent(),
  }) : episodeKey = Value(episodeKey),
       tvShowTmdbId = Value(tvShowTmdbId),
       seasonNumber = Value(seasonNumber),
       episodeNumber = Value(episodeNumber),
       title = Value(title),
       guestStars = Value(guestStars);
  static Insertable<EpisodeDO> custom({
    Expression<String>? episodeKey,
    Expression<String>? tvShowTmdbId,
    Expression<int>? seasonNumber,
    Expression<String>? tmdbId,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<DateTime>? airDate,
    Expression<String>? overview,
    Expression<String>? stillUrl,
    Expression<String>? guestStars,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (episodeKey != null) 'episode_key': episodeKey,
      if (tvShowTmdbId != null) 'tv_show_tmdb_id': tvShowTmdbId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (airDate != null) 'air_date': airDate,
      if (overview != null) 'overview': overview,
      if (stillUrl != null) 'still_url': stillUrl,
      if (guestStars != null) 'guest_stars': guestStars,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? episodeKey,
    Value<String>? tvShowTmdbId,
    Value<int>? seasonNumber,
    Value<String?>? tmdbId,
    Value<int>? episodeNumber,
    Value<String>? title,
    Value<DateTime?>? airDate,
    Value<String?>? overview,
    Value<String?>? stillUrl,
    Value<String>? guestStars,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      episodeKey: episodeKey ?? this.episodeKey,
      tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      tmdbId: tmdbId ?? this.tmdbId,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      airDate: airDate ?? this.airDate,
      overview: overview ?? this.overview,
      stillUrl: stillUrl ?? this.stillUrl,
      guestStars: guestStars ?? this.guestStars,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (episodeKey.present) {
      map['episode_key'] = Variable<String>(episodeKey.value);
    }
    if (tvShowTmdbId.present) {
      map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (airDate.present) {
      map['air_date'] = Variable<DateTime>(airDate.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (stillUrl.present) {
      map['still_url'] = Variable<String>(stillUrl.value);
    }
    if (guestStars.present) {
      map['guest_stars'] = Variable<String>(guestStars.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('episodeKey: $episodeKey, ')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('airDate: $airDate, ')
          ..write('overview: $overview, ')
          ..write('stillUrl: $stillUrl, ')
          ..write('guestStars: $guestStars, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorageSourcesTable extends StorageSources with TableInfo<$StorageSourcesTable, StorageSourceDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta('endpoint');
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootPathMeta = const VerificationMeta('rootPath');
  @override
  late final GeneratedColumn<String> rootPath = GeneratedColumn<String>(
    'root_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, name, type, endpoint, rootPath, enabled, username, password];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_sources';
  @override
  VerificationContext validateIntegrity(Insertable<StorageSourceDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta, sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(_endpointMeta, endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta));
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('root_path')) {
      context.handle(_rootPathMeta, rootPath.isAcceptableOrUnknown(data['root_path']!, _rootPathMeta));
    } else if (isInserting) {
      context.missing(_rootPathMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta, enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta, username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta, password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId};
  @override
  StorageSourceDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageSourceDO(
      sourceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      endpoint: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}endpoint'])!,
      rootPath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}root_path'])!,
      enabled: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      username: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}password'])!,
    );
  }

  @override
  $StorageSourcesTable createAlias(String alias) {
    return $StorageSourcesTable(attachedDatabase, alias);
  }
}

class StorageSourceDO extends DataClass implements Insertable<StorageSourceDO> {
  final String sourceId;
  final String name;
  final String type;
  final String endpoint;
  final String rootPath;
  final bool enabled;
  final String username;
  final String password;
  const StorageSourceDO({
    required this.sourceId,
    required this.name,
    required this.type,
    required this.endpoint,
    required this.rootPath,
    required this.enabled,
    required this.username,
    required this.password,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['endpoint'] = Variable<String>(endpoint);
    map['root_path'] = Variable<String>(rootPath);
    map['enabled'] = Variable<bool>(enabled);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    return map;
  }

  StorageSourcesCompanion toCompanion(bool nullToAbsent) {
    return StorageSourcesCompanion(
      sourceId: Value(sourceId),
      name: Value(name),
      type: Value(type),
      endpoint: Value(endpoint),
      rootPath: Value(rootPath),
      enabled: Value(enabled),
      username: Value(username),
      password: Value(password),
    );
  }

  factory StorageSourceDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageSourceDO(
      sourceId: serializer.fromJson<String>(json['sourceId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      rootPath: serializer.fromJson<String>(json['rootPath']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceId': serializer.toJson<String>(sourceId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'endpoint': serializer.toJson<String>(endpoint),
      'rootPath': serializer.toJson<String>(rootPath),
      'enabled': serializer.toJson<bool>(enabled),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
    };
  }

  StorageSourceDO copyWith({
    String? sourceId,
    String? name,
    String? type,
    String? endpoint,
    String? rootPath,
    bool? enabled,
    String? username,
    String? password,
  }) => StorageSourceDO(
    sourceId: sourceId ?? this.sourceId,
    name: name ?? this.name,
    type: type ?? this.type,
    endpoint: endpoint ?? this.endpoint,
    rootPath: rootPath ?? this.rootPath,
    enabled: enabled ?? this.enabled,
    username: username ?? this.username,
    password: password ?? this.password,
  );
  StorageSourceDO copyWithCompanion(StorageSourcesCompanion data) {
    return StorageSourceDO(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      rootPath: data.rootPath.present ? data.rootPath.value : this.rootPath,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageSourceDO(')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('endpoint: $endpoint, ')
          ..write('rootPath: $rootPath, ')
          ..write('enabled: $enabled, ')
          ..write('username: $username, ')
          ..write('password: $password')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, name, type, endpoint, rootPath, enabled, username, password);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageSourceDO &&
          other.sourceId == this.sourceId &&
          other.name == this.name &&
          other.type == this.type &&
          other.endpoint == this.endpoint &&
          other.rootPath == this.rootPath &&
          other.enabled == this.enabled &&
          other.username == this.username &&
          other.password == this.password);
}

class StorageSourcesCompanion extends UpdateCompanion<StorageSourceDO> {
  final Value<String> sourceId;
  final Value<String> name;
  final Value<String> type;
  final Value<String> endpoint;
  final Value<String> rootPath;
  final Value<bool> enabled;
  final Value<String> username;
  final Value<String> password;
  final Value<int> rowid;
  const StorageSourcesCompanion({
    this.sourceId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.rootPath = const Value.absent(),
    this.enabled = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageSourcesCompanion.insert({
    required String sourceId,
    required String name,
    required String type,
    required String endpoint,
    required String rootPath,
    required bool enabled,
    required String username,
    required String password,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       name = Value(name),
       type = Value(type),
       endpoint = Value(endpoint),
       rootPath = Value(rootPath),
       enabled = Value(enabled),
       username = Value(username),
       password = Value(password);
  static Insertable<StorageSourceDO> custom({
    Expression<String>? sourceId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? endpoint,
    Expression<String>? rootPath,
    Expression<bool>? enabled,
    Expression<String>? username,
    Expression<String>? password,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (endpoint != null) 'endpoint': endpoint,
      if (rootPath != null) 'root_path': rootPath,
      if (enabled != null) 'enabled': enabled,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageSourcesCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? name,
    Value<String>? type,
    Value<String>? endpoint,
    Value<String>? rootPath,
    Value<bool>? enabled,
    Value<String>? username,
    Value<String>? password,
    Value<int>? rowid,
  }) {
    return StorageSourcesCompanion(
      sourceId: sourceId ?? this.sourceId,
      name: name ?? this.name,
      type: type ?? this.type,
      endpoint: endpoint ?? this.endpoint,
      rootPath: rootPath ?? this.rootPath,
      enabled: enabled ?? this.enabled,
      username: username ?? this.username,
      password: password ?? this.password,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (rootPath.present) {
      map['root_path'] = Variable<String>(rootPath.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageSourcesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('endpoint: $endpoint, ')
          ..write('rootPath: $rootPath, ')
          ..write('enabled: $enabled, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, MovieDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<String> tmdbId = GeneratedColumn<String>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta('originalTitle');
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta('releaseYear');
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta('posterUrl');
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropUrlMeta = const VerificationMeta('backdropUrl');
  @override
  late final GeneratedColumn<String> backdropUrl = GeneratedColumn<String>(
    'backdrop_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta('logoUrl');
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _certificationMeta = const VerificationMeta('certification');
  @override
  late final GeneratedColumn<String> certification = GeneratedColumn<String>(
    'certification',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _genresMeta = const VerificationMeta('genres');
  @override
  late final GeneratedColumn<String> genres = GeneratedColumn<String>(
    'genres',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    releaseDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(Insertable<MovieDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(_tmdbIdMeta, tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta));
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(data['original_title']!, _originalTitleMeta),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(_releaseYearMeta, releaseYear.isAcceptableOrUnknown(data['release_year']!, _releaseYearMeta));
    }
    if (data.containsKey('release_date')) {
      context.handle(_releaseDateMeta, releaseDate.isAcceptableOrUnknown(data['release_date']!, _releaseDateMeta));
    }
    if (data.containsKey('poster_url')) {
      context.handle(_posterUrlMeta, posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta));
    }
    if (data.containsKey('backdrop_url')) {
      context.handle(_backdropUrlMeta, backdropUrl.isAcceptableOrUnknown(data['backdrop_url']!, _backdropUrlMeta));
    }
    if (data.containsKey('logo_url')) {
      context.handle(_logoUrlMeta, logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta));
    }
    if (data.containsKey('overview')) {
      context.handle(_overviewMeta, overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta));
    }
    if (data.containsKey('certification')) {
      context.handle(
        _certificationMeta,
        certification.isAcceptableOrUnknown(data['certification']!, _certificationMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('genres')) {
      context.handle(_genresMeta, genres.isAcceptableOrUnknown(data['genres']!, _genresMeta));
    } else if (isInserting) {
      context.missing(_genresMeta);
    }
    if (data.containsKey('cast')) {
      context.handle(_castMeta, cast.isAcceptableOrUnknown(data['cast']!, _castMeta));
    } else if (isInserting) {
      context.missing(_castMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  MovieDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovieDO(
      tmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tmdb_id'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      originalTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}original_title']),
      releaseYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}release_year']),
      releaseDate: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}release_date']),
      posterUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}poster_url']),
      backdropUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}backdrop_url']),
      logoUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}logo_url']),
      overview: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}overview']),
      certification: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}certification']),
      rating: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}rating'])!,
      genres: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}genres'])!,
      cast: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}cast'])!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class MovieDO extends DataClass implements Insertable<MovieDO> {
  final String tmdbId;
  final String title;
  final String? originalTitle;
  final int? releaseYear;
  final DateTime? releaseDate;
  final String? posterUrl;
  final String? backdropUrl;
  final String? logoUrl;
  final String? overview;
  final String? certification;
  final double rating;
  final String genres;
  final String cast;
  const MovieDO({
    required this.tmdbId,
    required this.title,
    this.originalTitle,
    this.releaseYear,
    this.releaseDate,
    this.posterUrl,
    this.backdropUrl,
    this.logoUrl,
    this.overview,
    this.certification,
    required this.rating,
    required this.genres,
    required this.cast,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<String>(tmdbId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || backdropUrl != null) {
      map['backdrop_url'] = Variable<String>(backdropUrl);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || certification != null) {
      map['certification'] = Variable<String>(certification);
    }
    map['rating'] = Variable<double>(rating);
    map['genres'] = Variable<String>(genres);
    map['cast'] = Variable<String>(cast);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      tmdbId: Value(tmdbId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent ? const Value.absent() : Value(originalTitle),
      releaseYear: releaseYear == null && nullToAbsent ? const Value.absent() : Value(releaseYear),
      releaseDate: releaseDate == null && nullToAbsent ? const Value.absent() : Value(releaseDate),
      posterUrl: posterUrl == null && nullToAbsent ? const Value.absent() : Value(posterUrl),
      backdropUrl: backdropUrl == null && nullToAbsent ? const Value.absent() : Value(backdropUrl),
      logoUrl: logoUrl == null && nullToAbsent ? const Value.absent() : Value(logoUrl),
      overview: overview == null && nullToAbsent ? const Value.absent() : Value(overview),
      certification: certification == null && nullToAbsent ? const Value.absent() : Value(certification),
      rating: Value(rating),
      genres: Value(genres),
      cast: Value(cast),
    );
  }

  factory MovieDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovieDO(
      tmdbId: serializer.fromJson<String>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      backdropUrl: serializer.fromJson<String?>(json['backdropUrl']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      overview: serializer.fromJson<String?>(json['overview']),
      certification: serializer.fromJson<String?>(json['certification']),
      rating: serializer.fromJson<double>(json['rating']),
      genres: serializer.fromJson<String>(json['genres']),
      cast: serializer.fromJson<String>(json['cast']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<String>(tmdbId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'backdropUrl': serializer.toJson<String?>(backdropUrl),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'overview': serializer.toJson<String?>(overview),
      'certification': serializer.toJson<String?>(certification),
      'rating': serializer.toJson<double>(rating),
      'genres': serializer.toJson<String>(genres),
      'cast': serializer.toJson<String>(cast),
    };
  }

  MovieDO copyWith({
    String? tmdbId,
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    Value<DateTime?> releaseDate = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    Value<String?> backdropUrl = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> certification = const Value.absent(),
    double? rating,
    String? genres,
    String? cast,
  }) => MovieDO(
    tmdbId: tmdbId ?? this.tmdbId,
    title: title ?? this.title,
    originalTitle: originalTitle.present ? originalTitle.value : this.originalTitle,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    backdropUrl: backdropUrl.present ? backdropUrl.value : this.backdropUrl,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    overview: overview.present ? overview.value : this.overview,
    certification: certification.present ? certification.value : this.certification,
    rating: rating ?? this.rating,
    genres: genres ?? this.genres,
    cast: cast ?? this.cast,
  );
  MovieDO copyWithCompanion(MoviesCompanion data) {
    return MovieDO(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present ? data.originalTitle.value : this.originalTitle,
      releaseYear: data.releaseYear.present ? data.releaseYear.value : this.releaseYear,
      releaseDate: data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      backdropUrl: data.backdropUrl.present ? data.backdropUrl.value : this.backdropUrl,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      overview: data.overview.present ? data.overview.value : this.overview,
      certification: data.certification.present ? data.certification.value : this.certification,
      rating: data.rating.present ? data.rating.value : this.rating,
      genres: data.genres.present ? data.genres.value : this.genres,
      cast: data.cast.present ? data.cast.value : this.cast,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovieDO(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tmdbId,
    title,
    originalTitle,
    releaseYear,
    releaseDate,
    posterUrl,
    backdropUrl,
    logoUrl,
    overview,
    certification,
    rating,
    genres,
    cast,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovieDO &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.releaseYear == this.releaseYear &&
          other.releaseDate == this.releaseDate &&
          other.posterUrl == this.posterUrl &&
          other.backdropUrl == this.backdropUrl &&
          other.logoUrl == this.logoUrl &&
          other.overview == this.overview &&
          other.certification == this.certification &&
          other.rating == this.rating &&
          other.genres == this.genres &&
          other.cast == this.cast);
}

class MoviesCompanion extends UpdateCompanion<MovieDO> {
  final Value<String> tmdbId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<int?> releaseYear;
  final Value<DateTime?> releaseDate;
  final Value<String?> posterUrl;
  final Value<String?> backdropUrl;
  final Value<String?> logoUrl;
  final Value<String?> overview;
  final Value<String?> certification;
  final Value<double> rating;
  final Value<String> genres;
  final Value<String> cast;
  final Value<int> rowid;
  const MoviesCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    this.rating = const Value.absent(),
    this.genres = const Value.absent(),
    this.cast = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required String tmdbId,
    required String title,
    this.originalTitle = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.backdropUrl = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.overview = const Value.absent(),
    this.certification = const Value.absent(),
    required double rating,
    required String genres,
    required String cast,
    this.rowid = const Value.absent(),
  }) : tmdbId = Value(tmdbId),
       title = Value(title),
       rating = Value(rating),
       genres = Value(genres),
       cast = Value(cast);
  static Insertable<MovieDO> custom({
    Expression<String>? tmdbId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<int>? releaseYear,
    Expression<DateTime>? releaseDate,
    Expression<String>? posterUrl,
    Expression<String>? backdropUrl,
    Expression<String>? logoUrl,
    Expression<String>? overview,
    Expression<String>? certification,
    Expression<double>? rating,
    Expression<String>? genres,
    Expression<String>? cast,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (releaseYear != null) 'release_year': releaseYear,
      if (releaseDate != null) 'release_date': releaseDate,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (backdropUrl != null) 'backdrop_url': backdropUrl,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (overview != null) 'overview': overview,
      if (certification != null) 'certification': certification,
      if (rating != null) 'rating': rating,
      if (genres != null) 'genres': genres,
      if (cast != null) 'cast': cast,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith({
    Value<String>? tmdbId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<int?>? releaseYear,
    Value<DateTime?>? releaseDate,
    Value<String?>? posterUrl,
    Value<String?>? backdropUrl,
    Value<String?>? logoUrl,
    Value<String?>? overview,
    Value<String?>? certification,
    Value<double>? rating,
    Value<String>? genres,
    Value<String>? cast,
    Value<int>? rowid,
  }) {
    return MoviesCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      releaseYear: releaseYear ?? this.releaseYear,
      releaseDate: releaseDate ?? this.releaseDate,
      posterUrl: posterUrl ?? this.posterUrl,
      backdropUrl: backdropUrl ?? this.backdropUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      overview: overview ?? this.overview,
      certification: certification ?? this.certification,
      rating: rating ?? this.rating,
      genres: genres ?? this.genres,
      cast: cast ?? this.cast,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<String>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (backdropUrl.present) {
      map['backdrop_url'] = Variable<String>(backdropUrl.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (certification.present) {
      map['certification'] = Variable<String>(certification.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(genres.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('backdropUrl: $backdropUrl, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('overview: $overview, ')
          ..write('certification: $certification, ')
          ..write('rating: $rating, ')
          ..write('genres: $genres, ')
          ..write('cast: $cast, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MediaFiles extends Table with TableInfo<MediaFiles, MediaFileDO> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MediaFiles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta('sourceId');
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES storage_sources(source_id)ON DELETE CASCADE',
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta('fileName');
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parsedTitleMeta = const VerificationMeta('parsedTitle');
  late final GeneratedColumn<String> parsedTitle = GeneratedColumn<String>(
    'parsed_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _parsedYearMeta = const VerificationMeta('parsedYear');
  late final GeneratedColumn<int> parsedYear = GeneratedColumn<int>(
    'parsed_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _parsedSeasonMeta = const VerificationMeta('parsedSeason');
  late final GeneratedColumn<int> parsedSeason = GeneratedColumn<int>(
    'parsed_season',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _parsedEpisodeMeta = const VerificationMeta('parsedEpisode');
  late final GeneratedColumn<int> parsedEpisode = GeneratedColumn<int>(
    'parsed_episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta('mediaType');
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _explicitTmdbIdMeta = const VerificationMeta('explicitTmdbId');
  late final GeneratedColumn<String> explicitTmdbId = GeneratedColumn<String>(
    'explicit_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _movieTmdbIdMeta = const VerificationMeta('movieTmdbId');
  late final GeneratedColumn<String> movieTmdbId = GeneratedColumn<String>(
    'movie_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES movies(tmdb_id)',
  );
  static const VerificationMeta _tvShowTmdbIdMeta = const VerificationMeta('tvShowTmdbId');
  late final GeneratedColumn<String> tvShowTmdbId = GeneratedColumn<String>(
    'tv_show_tmdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES t_v_shows(tmdb_id)',
  );
  static const VerificationMeta _episodeKeyMeta = const VerificationMeta('episodeKey');
  late final GeneratedColumn<String> episodeKey = GeneratedColumn<String>(
    'episode_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _metadataMatchStatusMeta = const VerificationMeta('metadataMatchStatus');
  late final GeneratedColumn<String> metadataMatchStatus = GeneratedColumn<String>(
    'metadata_match_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _containerMeta = const VerificationMeta('container');
  late final GeneratedColumn<String> container = GeneratedColumn<String>(
    'container',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _videoCodecMeta = const VerificationMeta('videoCodec');
  late final GeneratedColumn<String> videoCodec = GeneratedColumn<String>(
    'video_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _audioCodecMeta = const VerificationMeta('audioCodec');
  late final GeneratedColumn<String> audioCodec = GeneratedColumn<String>(
    'audio_codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _audioChannelsMeta = const VerificationMeta('audioChannels');
  late final GeneratedColumn<String> audioChannels = GeneratedColumn<String>(
    'audio_channels',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isHdrMeta = const VerificationMeta('isHdr');
  late final GeneratedColumn<bool> isHdr = GeneratedColumn<bool>(
    'is_hdr',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hdrFormatMeta = const VerificationMeta('hdrFormat');
  late final GeneratedColumn<String> hdrFormat = GeneratedColumn<String>(
    'hdr_format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _versionLabelMeta = const VerificationMeta('versionLabel');
  late final GeneratedColumn<String> versionLabel = GeneratedColumn<String>(
    'version_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _durationMeta = const VerificationMeta('duration');
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _watchStatusMeta = const VerificationMeta('watchStatus');
  late final GeneratedColumn<String> watchStatus = GeneratedColumn<String>(
    'watch_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastWatchedAtMeta = const VerificationMeta('lastWatchedAt');
  late final GeneratedColumn<DateTime> lastWatchedAt = GeneratedColumn<DateTime>(
    'last_watched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta('isFavorite');
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta('addedAt');
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    path,
    fileName,
    parsedTitle,
    parsedYear,
    parsedSeason,
    parsedEpisode,
    mediaType,
    explicitTmdbId,
    movieTmdbId,
    tvShowTmdbId,
    episodeKey,
    metadataMatchStatus,
    size,
    container,
    width,
    height,
    videoCodec,
    audioCodec,
    audioChannels,
    isHdr,
    hdrFormat,
    versionLabel,
    duration,
    position,
    watchStatus,
    lastWatchedAt,
    isFavorite,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(Insertable<MediaFileDO> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta, sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(_pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta, fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('parsed_title')) {
      context.handle(_parsedTitleMeta, parsedTitle.isAcceptableOrUnknown(data['parsed_title']!, _parsedTitleMeta));
    } else if (isInserting) {
      context.missing(_parsedTitleMeta);
    }
    if (data.containsKey('parsed_year')) {
      context.handle(_parsedYearMeta, parsedYear.isAcceptableOrUnknown(data['parsed_year']!, _parsedYearMeta));
    }
    if (data.containsKey('parsed_season')) {
      context.handle(_parsedSeasonMeta, parsedSeason.isAcceptableOrUnknown(data['parsed_season']!, _parsedSeasonMeta));
    }
    if (data.containsKey('parsed_episode')) {
      context.handle(
        _parsedEpisodeMeta,
        parsedEpisode.isAcceptableOrUnknown(data['parsed_episode']!, _parsedEpisodeMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta, mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('explicit_tmdb_id')) {
      context.handle(
        _explicitTmdbIdMeta,
        explicitTmdbId.isAcceptableOrUnknown(data['explicit_tmdb_id']!, _explicitTmdbIdMeta),
      );
    }
    if (data.containsKey('movie_tmdb_id')) {
      context.handle(_movieTmdbIdMeta, movieTmdbId.isAcceptableOrUnknown(data['movie_tmdb_id']!, _movieTmdbIdMeta));
    }
    if (data.containsKey('tv_show_tmdb_id')) {
      context.handle(
        _tvShowTmdbIdMeta,
        tvShowTmdbId.isAcceptableOrUnknown(data['tv_show_tmdb_id']!, _tvShowTmdbIdMeta),
      );
    }
    if (data.containsKey('episode_key')) {
      context.handle(_episodeKeyMeta, episodeKey.isAcceptableOrUnknown(data['episode_key']!, _episodeKeyMeta));
    }
    if (data.containsKey('metadata_match_status')) {
      context.handle(
        _metadataMatchStatusMeta,
        metadataMatchStatus.isAcceptableOrUnknown(data['metadata_match_status']!, _metadataMatchStatusMeta),
      );
    } else if (isInserting) {
      context.missing(_metadataMatchStatusMeta);
    }
    if (data.containsKey('size')) {
      context.handle(_sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('container')) {
      context.handle(_containerMeta, container.isAcceptableOrUnknown(data['container']!, _containerMeta));
    }
    if (data.containsKey('width')) {
      context.handle(_widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta, height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('video_codec')) {
      context.handle(_videoCodecMeta, videoCodec.isAcceptableOrUnknown(data['video_codec']!, _videoCodecMeta));
    }
    if (data.containsKey('audio_codec')) {
      context.handle(_audioCodecMeta, audioCodec.isAcceptableOrUnknown(data['audio_codec']!, _audioCodecMeta));
    }
    if (data.containsKey('audio_channels')) {
      context.handle(
        _audioChannelsMeta,
        audioChannels.isAcceptableOrUnknown(data['audio_channels']!, _audioChannelsMeta),
      );
    }
    if (data.containsKey('is_hdr')) {
      context.handle(_isHdrMeta, isHdr.isAcceptableOrUnknown(data['is_hdr']!, _isHdrMeta));
    } else if (isInserting) {
      context.missing(_isHdrMeta);
    }
    if (data.containsKey('hdr_format')) {
      context.handle(_hdrFormatMeta, hdrFormat.isAcceptableOrUnknown(data['hdr_format']!, _hdrFormatMeta));
    }
    if (data.containsKey('version_label')) {
      context.handle(_versionLabelMeta, versionLabel.isAcceptableOrUnknown(data['version_label']!, _versionLabelMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta, duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('watch_status')) {
      context.handle(_watchStatusMeta, watchStatus.isAcceptableOrUnknown(data['watch_status']!, _watchStatusMeta));
    } else if (isInserting) {
      context.missing(_watchStatusMeta);
    }
    if (data.containsKey('last_watched_at')) {
      context.handle(
        _lastWatchedAtMeta,
        lastWatchedAt.isAcceptableOrUnknown(data['last_watched_at']!, _lastWatchedAtMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(_isFavoriteMeta, isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta));
    } else if (isInserting) {
      context.missing(_isFavoriteMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(_addedAtMeta, addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta));
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, path},
  ];
  @override
  MediaFileDO map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFileDO(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      sourceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      path: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      fileName: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      parsedTitle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}parsed_title'])!,
      parsedYear: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_year']),
      parsedSeason: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_season']),
      parsedEpisode: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}parsed_episode']),
      mediaType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      explicitTmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explicit_tmdb_id'],
      ),
      movieTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}movie_tmdb_id']),
      tvShowTmdbId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tv_show_tmdb_id']),
      episodeKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}episode_key']),
      metadataMatchStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_match_status'],
      )!,
      size: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      container: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}container']),
      width: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}height']),
      videoCodec: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}video_codec']),
      audioCodec: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_codec']),
      audioChannels: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}audio_channels']),
      isHdr: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_hdr'])!,
      hdrFormat: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hdr_format']),
      versionLabel: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}version_label']),
      duration: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      watchStatus: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}watch_status'])!,
      lastWatchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched_at'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      addedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}added_at'])!,
    );
  }

  @override
  MediaFiles createAlias(String alias) {
    return MediaFiles(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(source_id, path)',
    'FOREIGN KEY(episode_key, tv_show_tmdb_id)REFERENCES episodes(episode_key, tv_show_tmdb_id)',
    'CHECK(movie_tmdb_id IS NULL OR(media_type = \'movie\' AND tv_show_tmdb_id IS NULL AND episode_key IS NULL))',
    'CHECK(tv_show_tmdb_id IS NULL OR media_type = \'episode\')',
    'CHECK(episode_key IS NULL OR tv_show_tmdb_id IS NOT NULL)',
    'CHECK(size >= 0 AND duration >= 0 AND position >= 0)',
    'CHECK(parsed_season IS NULL OR parsed_season >= 0)',
    'CHECK(parsed_episode IS NULL OR parsed_episode >= 0)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MediaFileDO extends DataClass implements Insertable<MediaFileDO> {
  final int id;
  final String sourceId;
  final String path;
  final String fileName;
  final String parsedTitle;
  final int? parsedYear;
  final int? parsedSeason;
  final int? parsedEpisode;
  final String mediaType;
  final String? explicitTmdbId;
  final String? movieTmdbId;
  final String? tvShowTmdbId;
  final String? episodeKey;
  final String metadataMatchStatus;
  final int size;
  final String? container;
  final int? width;
  final int? height;
  final String? videoCodec;
  final String? audioCodec;
  final String? audioChannels;
  final bool isHdr;
  final String? hdrFormat;
  final String? versionLabel;
  final int duration;
  final int position;
  final String watchStatus;
  final DateTime? lastWatchedAt;
  final bool isFavorite;
  final DateTime addedAt;
  const MediaFileDO({
    required this.id,
    required this.sourceId,
    required this.path,
    required this.fileName,
    required this.parsedTitle,
    this.parsedYear,
    this.parsedSeason,
    this.parsedEpisode,
    required this.mediaType,
    this.explicitTmdbId,
    this.movieTmdbId,
    this.tvShowTmdbId,
    this.episodeKey,
    required this.metadataMatchStatus,
    required this.size,
    this.container,
    this.width,
    this.height,
    this.videoCodec,
    this.audioCodec,
    this.audioChannels,
    required this.isHdr,
    this.hdrFormat,
    this.versionLabel,
    required this.duration,
    required this.position,
    required this.watchStatus,
    this.lastWatchedAt,
    required this.isFavorite,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<String>(sourceId);
    map['path'] = Variable<String>(path);
    map['file_name'] = Variable<String>(fileName);
    map['parsed_title'] = Variable<String>(parsedTitle);
    if (!nullToAbsent || parsedYear != null) {
      map['parsed_year'] = Variable<int>(parsedYear);
    }
    if (!nullToAbsent || parsedSeason != null) {
      map['parsed_season'] = Variable<int>(parsedSeason);
    }
    if (!nullToAbsent || parsedEpisode != null) {
      map['parsed_episode'] = Variable<int>(parsedEpisode);
    }
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || explicitTmdbId != null) {
      map['explicit_tmdb_id'] = Variable<String>(explicitTmdbId);
    }
    if (!nullToAbsent || movieTmdbId != null) {
      map['movie_tmdb_id'] = Variable<String>(movieTmdbId);
    }
    if (!nullToAbsent || tvShowTmdbId != null) {
      map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId);
    }
    if (!nullToAbsent || episodeKey != null) {
      map['episode_key'] = Variable<String>(episodeKey);
    }
    map['metadata_match_status'] = Variable<String>(metadataMatchStatus);
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || container != null) {
      map['container'] = Variable<String>(container);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || videoCodec != null) {
      map['video_codec'] = Variable<String>(videoCodec);
    }
    if (!nullToAbsent || audioCodec != null) {
      map['audio_codec'] = Variable<String>(audioCodec);
    }
    if (!nullToAbsent || audioChannels != null) {
      map['audio_channels'] = Variable<String>(audioChannels);
    }
    map['is_hdr'] = Variable<bool>(isHdr);
    if (!nullToAbsent || hdrFormat != null) {
      map['hdr_format'] = Variable<String>(hdrFormat);
    }
    if (!nullToAbsent || versionLabel != null) {
      map['version_label'] = Variable<String>(versionLabel);
    }
    map['duration'] = Variable<int>(duration);
    map['position'] = Variable<int>(position);
    map['watch_status'] = Variable<String>(watchStatus);
    if (!nullToAbsent || lastWatchedAt != null) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  MediaFilesCompanion toCompanion(bool nullToAbsent) {
    return MediaFilesCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      path: Value(path),
      fileName: Value(fileName),
      parsedTitle: Value(parsedTitle),
      parsedYear: parsedYear == null && nullToAbsent ? const Value.absent() : Value(parsedYear),
      parsedSeason: parsedSeason == null && nullToAbsent ? const Value.absent() : Value(parsedSeason),
      parsedEpisode: parsedEpisode == null && nullToAbsent ? const Value.absent() : Value(parsedEpisode),
      mediaType: Value(mediaType),
      explicitTmdbId: explicitTmdbId == null && nullToAbsent ? const Value.absent() : Value(explicitTmdbId),
      movieTmdbId: movieTmdbId == null && nullToAbsent ? const Value.absent() : Value(movieTmdbId),
      tvShowTmdbId: tvShowTmdbId == null && nullToAbsent ? const Value.absent() : Value(tvShowTmdbId),
      episodeKey: episodeKey == null && nullToAbsent ? const Value.absent() : Value(episodeKey),
      metadataMatchStatus: Value(metadataMatchStatus),
      size: Value(size),
      container: container == null && nullToAbsent ? const Value.absent() : Value(container),
      width: width == null && nullToAbsent ? const Value.absent() : Value(width),
      height: height == null && nullToAbsent ? const Value.absent() : Value(height),
      videoCodec: videoCodec == null && nullToAbsent ? const Value.absent() : Value(videoCodec),
      audioCodec: audioCodec == null && nullToAbsent ? const Value.absent() : Value(audioCodec),
      audioChannels: audioChannels == null && nullToAbsent ? const Value.absent() : Value(audioChannels),
      isHdr: Value(isHdr),
      hdrFormat: hdrFormat == null && nullToAbsent ? const Value.absent() : Value(hdrFormat),
      versionLabel: versionLabel == null && nullToAbsent ? const Value.absent() : Value(versionLabel),
      duration: Value(duration),
      position: Value(position),
      watchStatus: Value(watchStatus),
      lastWatchedAt: lastWatchedAt == null && nullToAbsent ? const Value.absent() : Value(lastWatchedAt),
      isFavorite: Value(isFavorite),
      addedAt: Value(addedAt),
    );
  }

  factory MediaFileDO.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFileDO(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<String>(json['source_id']),
      path: serializer.fromJson<String>(json['path']),
      fileName: serializer.fromJson<String>(json['file_name']),
      parsedTitle: serializer.fromJson<String>(json['parsed_title']),
      parsedYear: serializer.fromJson<int?>(json['parsed_year']),
      parsedSeason: serializer.fromJson<int?>(json['parsed_season']),
      parsedEpisode: serializer.fromJson<int?>(json['parsed_episode']),
      mediaType: serializer.fromJson<String>(json['media_type']),
      explicitTmdbId: serializer.fromJson<String?>(json['explicit_tmdb_id']),
      movieTmdbId: serializer.fromJson<String?>(json['movie_tmdb_id']),
      tvShowTmdbId: serializer.fromJson<String?>(json['tv_show_tmdb_id']),
      episodeKey: serializer.fromJson<String?>(json['episode_key']),
      metadataMatchStatus: serializer.fromJson<String>(json['metadata_match_status']),
      size: serializer.fromJson<int>(json['size']),
      container: serializer.fromJson<String?>(json['container']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      videoCodec: serializer.fromJson<String?>(json['video_codec']),
      audioCodec: serializer.fromJson<String?>(json['audio_codec']),
      audioChannels: serializer.fromJson<String?>(json['audio_channels']),
      isHdr: serializer.fromJson<bool>(json['is_hdr']),
      hdrFormat: serializer.fromJson<String?>(json['hdr_format']),
      versionLabel: serializer.fromJson<String?>(json['version_label']),
      duration: serializer.fromJson<int>(json['duration']),
      position: serializer.fromJson<int>(json['position']),
      watchStatus: serializer.fromJson<String>(json['watch_status']),
      lastWatchedAt: serializer.fromJson<DateTime?>(json['last_watched_at']),
      isFavorite: serializer.fromJson<bool>(json['is_favorite']),
      addedAt: serializer.fromJson<DateTime>(json['added_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'source_id': serializer.toJson<String>(sourceId),
      'path': serializer.toJson<String>(path),
      'file_name': serializer.toJson<String>(fileName),
      'parsed_title': serializer.toJson<String>(parsedTitle),
      'parsed_year': serializer.toJson<int?>(parsedYear),
      'parsed_season': serializer.toJson<int?>(parsedSeason),
      'parsed_episode': serializer.toJson<int?>(parsedEpisode),
      'media_type': serializer.toJson<String>(mediaType),
      'explicit_tmdb_id': serializer.toJson<String?>(explicitTmdbId),
      'movie_tmdb_id': serializer.toJson<String?>(movieTmdbId),
      'tv_show_tmdb_id': serializer.toJson<String?>(tvShowTmdbId),
      'episode_key': serializer.toJson<String?>(episodeKey),
      'metadata_match_status': serializer.toJson<String>(metadataMatchStatus),
      'size': serializer.toJson<int>(size),
      'container': serializer.toJson<String?>(container),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'video_codec': serializer.toJson<String?>(videoCodec),
      'audio_codec': serializer.toJson<String?>(audioCodec),
      'audio_channels': serializer.toJson<String?>(audioChannels),
      'is_hdr': serializer.toJson<bool>(isHdr),
      'hdr_format': serializer.toJson<String?>(hdrFormat),
      'version_label': serializer.toJson<String?>(versionLabel),
      'duration': serializer.toJson<int>(duration),
      'position': serializer.toJson<int>(position),
      'watch_status': serializer.toJson<String>(watchStatus),
      'last_watched_at': serializer.toJson<DateTime?>(lastWatchedAt),
      'is_favorite': serializer.toJson<bool>(isFavorite),
      'added_at': serializer.toJson<DateTime>(addedAt),
    };
  }

  MediaFileDO copyWith({
    int? id,
    String? sourceId,
    String? path,
    String? fileName,
    String? parsedTitle,
    Value<int?> parsedYear = const Value.absent(),
    Value<int?> parsedSeason = const Value.absent(),
    Value<int?> parsedEpisode = const Value.absent(),
    String? mediaType,
    Value<String?> explicitTmdbId = const Value.absent(),
    Value<String?> movieTmdbId = const Value.absent(),
    Value<String?> tvShowTmdbId = const Value.absent(),
    Value<String?> episodeKey = const Value.absent(),
    String? metadataMatchStatus,
    int? size,
    Value<String?> container = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<String?> videoCodec = const Value.absent(),
    Value<String?> audioCodec = const Value.absent(),
    Value<String?> audioChannels = const Value.absent(),
    bool? isHdr,
    Value<String?> hdrFormat = const Value.absent(),
    Value<String?> versionLabel = const Value.absent(),
    int? duration,
    int? position,
    String? watchStatus,
    Value<DateTime?> lastWatchedAt = const Value.absent(),
    bool? isFavorite,
    DateTime? addedAt,
  }) => MediaFileDO(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    path: path ?? this.path,
    fileName: fileName ?? this.fileName,
    parsedTitle: parsedTitle ?? this.parsedTitle,
    parsedYear: parsedYear.present ? parsedYear.value : this.parsedYear,
    parsedSeason: parsedSeason.present ? parsedSeason.value : this.parsedSeason,
    parsedEpisode: parsedEpisode.present ? parsedEpisode.value : this.parsedEpisode,
    mediaType: mediaType ?? this.mediaType,
    explicitTmdbId: explicitTmdbId.present ? explicitTmdbId.value : this.explicitTmdbId,
    movieTmdbId: movieTmdbId.present ? movieTmdbId.value : this.movieTmdbId,
    tvShowTmdbId: tvShowTmdbId.present ? tvShowTmdbId.value : this.tvShowTmdbId,
    episodeKey: episodeKey.present ? episodeKey.value : this.episodeKey,
    metadataMatchStatus: metadataMatchStatus ?? this.metadataMatchStatus,
    size: size ?? this.size,
    container: container.present ? container.value : this.container,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    videoCodec: videoCodec.present ? videoCodec.value : this.videoCodec,
    audioCodec: audioCodec.present ? audioCodec.value : this.audioCodec,
    audioChannels: audioChannels.present ? audioChannels.value : this.audioChannels,
    isHdr: isHdr ?? this.isHdr,
    hdrFormat: hdrFormat.present ? hdrFormat.value : this.hdrFormat,
    versionLabel: versionLabel.present ? versionLabel.value : this.versionLabel,
    duration: duration ?? this.duration,
    position: position ?? this.position,
    watchStatus: watchStatus ?? this.watchStatus,
    lastWatchedAt: lastWatchedAt.present ? lastWatchedAt.value : this.lastWatchedAt,
    isFavorite: isFavorite ?? this.isFavorite,
    addedAt: addedAt ?? this.addedAt,
  );
  MediaFileDO copyWithCompanion(MediaFilesCompanion data) {
    return MediaFileDO(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      path: data.path.present ? data.path.value : this.path,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      parsedTitle: data.parsedTitle.present ? data.parsedTitle.value : this.parsedTitle,
      parsedYear: data.parsedYear.present ? data.parsedYear.value : this.parsedYear,
      parsedSeason: data.parsedSeason.present ? data.parsedSeason.value : this.parsedSeason,
      parsedEpisode: data.parsedEpisode.present ? data.parsedEpisode.value : this.parsedEpisode,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      explicitTmdbId: data.explicitTmdbId.present ? data.explicitTmdbId.value : this.explicitTmdbId,
      movieTmdbId: data.movieTmdbId.present ? data.movieTmdbId.value : this.movieTmdbId,
      tvShowTmdbId: data.tvShowTmdbId.present ? data.tvShowTmdbId.value : this.tvShowTmdbId,
      episodeKey: data.episodeKey.present ? data.episodeKey.value : this.episodeKey,
      metadataMatchStatus: data.metadataMatchStatus.present ? data.metadataMatchStatus.value : this.metadataMatchStatus,
      size: data.size.present ? data.size.value : this.size,
      container: data.container.present ? data.container.value : this.container,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      videoCodec: data.videoCodec.present ? data.videoCodec.value : this.videoCodec,
      audioCodec: data.audioCodec.present ? data.audioCodec.value : this.audioCodec,
      audioChannels: data.audioChannels.present ? data.audioChannels.value : this.audioChannels,
      isHdr: data.isHdr.present ? data.isHdr.value : this.isHdr,
      hdrFormat: data.hdrFormat.present ? data.hdrFormat.value : this.hdrFormat,
      versionLabel: data.versionLabel.present ? data.versionLabel.value : this.versionLabel,
      duration: data.duration.present ? data.duration.value : this.duration,
      position: data.position.present ? data.position.value : this.position,
      watchStatus: data.watchStatus.present ? data.watchStatus.value : this.watchStatus,
      lastWatchedAt: data.lastWatchedAt.present ? data.lastWatchedAt.value : this.lastWatchedAt,
      isFavorite: data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFileDO(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('path: $path, ')
          ..write('fileName: $fileName, ')
          ..write('parsedTitle: $parsedTitle, ')
          ..write('parsedYear: $parsedYear, ')
          ..write('parsedSeason: $parsedSeason, ')
          ..write('parsedEpisode: $parsedEpisode, ')
          ..write('mediaType: $mediaType, ')
          ..write('explicitTmdbId: $explicitTmdbId, ')
          ..write('movieTmdbId: $movieTmdbId, ')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('episodeKey: $episodeKey, ')
          ..write('metadataMatchStatus: $metadataMatchStatus, ')
          ..write('size: $size, ')
          ..write('container: $container, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('audioChannels: $audioChannels, ')
          ..write('isHdr: $isHdr, ')
          ..write('hdrFormat: $hdrFormat, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('duration: $duration, ')
          ..write('position: $position, ')
          ..write('watchStatus: $watchStatus, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourceId,
    path,
    fileName,
    parsedTitle,
    parsedYear,
    parsedSeason,
    parsedEpisode,
    mediaType,
    explicitTmdbId,
    movieTmdbId,
    tvShowTmdbId,
    episodeKey,
    metadataMatchStatus,
    size,
    container,
    width,
    height,
    videoCodec,
    audioCodec,
    audioChannels,
    isHdr,
    hdrFormat,
    versionLabel,
    duration,
    position,
    watchStatus,
    lastWatchedAt,
    isFavorite,
    addedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFileDO &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.path == this.path &&
          other.fileName == this.fileName &&
          other.parsedTitle == this.parsedTitle &&
          other.parsedYear == this.parsedYear &&
          other.parsedSeason == this.parsedSeason &&
          other.parsedEpisode == this.parsedEpisode &&
          other.mediaType == this.mediaType &&
          other.explicitTmdbId == this.explicitTmdbId &&
          other.movieTmdbId == this.movieTmdbId &&
          other.tvShowTmdbId == this.tvShowTmdbId &&
          other.episodeKey == this.episodeKey &&
          other.metadataMatchStatus == this.metadataMatchStatus &&
          other.size == this.size &&
          other.container == this.container &&
          other.width == this.width &&
          other.height == this.height &&
          other.videoCodec == this.videoCodec &&
          other.audioCodec == this.audioCodec &&
          other.audioChannels == this.audioChannels &&
          other.isHdr == this.isHdr &&
          other.hdrFormat == this.hdrFormat &&
          other.versionLabel == this.versionLabel &&
          other.duration == this.duration &&
          other.position == this.position &&
          other.watchStatus == this.watchStatus &&
          other.lastWatchedAt == this.lastWatchedAt &&
          other.isFavorite == this.isFavorite &&
          other.addedAt == this.addedAt);
}

class MediaFilesCompanion extends UpdateCompanion<MediaFileDO> {
  final Value<int> id;
  final Value<String> sourceId;
  final Value<String> path;
  final Value<String> fileName;
  final Value<String> parsedTitle;
  final Value<int?> parsedYear;
  final Value<int?> parsedSeason;
  final Value<int?> parsedEpisode;
  final Value<String> mediaType;
  final Value<String?> explicitTmdbId;
  final Value<String?> movieTmdbId;
  final Value<String?> tvShowTmdbId;
  final Value<String?> episodeKey;
  final Value<String> metadataMatchStatus;
  final Value<int> size;
  final Value<String?> container;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> videoCodec;
  final Value<String?> audioCodec;
  final Value<String?> audioChannels;
  final Value<bool> isHdr;
  final Value<String?> hdrFormat;
  final Value<String?> versionLabel;
  final Value<int> duration;
  final Value<int> position;
  final Value<String> watchStatus;
  final Value<DateTime?> lastWatchedAt;
  final Value<bool> isFavorite;
  final Value<DateTime> addedAt;
  const MediaFilesCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.path = const Value.absent(),
    this.fileName = const Value.absent(),
    this.parsedTitle = const Value.absent(),
    this.parsedYear = const Value.absent(),
    this.parsedSeason = const Value.absent(),
    this.parsedEpisode = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.explicitTmdbId = const Value.absent(),
    this.movieTmdbId = const Value.absent(),
    this.tvShowTmdbId = const Value.absent(),
    this.episodeKey = const Value.absent(),
    this.metadataMatchStatus = const Value.absent(),
    this.size = const Value.absent(),
    this.container = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.audioChannels = const Value.absent(),
    this.isHdr = const Value.absent(),
    this.hdrFormat = const Value.absent(),
    this.versionLabel = const Value.absent(),
    this.duration = const Value.absent(),
    this.position = const Value.absent(),
    this.watchStatus = const Value.absent(),
    this.lastWatchedAt = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    this.id = const Value.absent(),
    required String sourceId,
    required String path,
    required String fileName,
    required String parsedTitle,
    this.parsedYear = const Value.absent(),
    this.parsedSeason = const Value.absent(),
    this.parsedEpisode = const Value.absent(),
    required String mediaType,
    this.explicitTmdbId = const Value.absent(),
    this.movieTmdbId = const Value.absent(),
    this.tvShowTmdbId = const Value.absent(),
    this.episodeKey = const Value.absent(),
    required String metadataMatchStatus,
    required int size,
    this.container = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.videoCodec = const Value.absent(),
    this.audioCodec = const Value.absent(),
    this.audioChannels = const Value.absent(),
    required bool isHdr,
    this.hdrFormat = const Value.absent(),
    this.versionLabel = const Value.absent(),
    required int duration,
    required int position,
    required String watchStatus,
    this.lastWatchedAt = const Value.absent(),
    required bool isFavorite,
    required DateTime addedAt,
  }) : sourceId = Value(sourceId),
       path = Value(path),
       fileName = Value(fileName),
       parsedTitle = Value(parsedTitle),
       mediaType = Value(mediaType),
       metadataMatchStatus = Value(metadataMatchStatus),
       size = Value(size),
       isHdr = Value(isHdr),
       duration = Value(duration),
       position = Value(position),
       watchStatus = Value(watchStatus),
       isFavorite = Value(isFavorite),
       addedAt = Value(addedAt);
  static Insertable<MediaFileDO> custom({
    Expression<int>? id,
    Expression<String>? sourceId,
    Expression<String>? path,
    Expression<String>? fileName,
    Expression<String>? parsedTitle,
    Expression<int>? parsedYear,
    Expression<int>? parsedSeason,
    Expression<int>? parsedEpisode,
    Expression<String>? mediaType,
    Expression<String>? explicitTmdbId,
    Expression<String>? movieTmdbId,
    Expression<String>? tvShowTmdbId,
    Expression<String>? episodeKey,
    Expression<String>? metadataMatchStatus,
    Expression<int>? size,
    Expression<String>? container,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? videoCodec,
    Expression<String>? audioCodec,
    Expression<String>? audioChannels,
    Expression<bool>? isHdr,
    Expression<String>? hdrFormat,
    Expression<String>? versionLabel,
    Expression<int>? duration,
    Expression<int>? position,
    Expression<String>? watchStatus,
    Expression<DateTime>? lastWatchedAt,
    Expression<bool>? isFavorite,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (path != null) 'path': path,
      if (fileName != null) 'file_name': fileName,
      if (parsedTitle != null) 'parsed_title': parsedTitle,
      if (parsedYear != null) 'parsed_year': parsedYear,
      if (parsedSeason != null) 'parsed_season': parsedSeason,
      if (parsedEpisode != null) 'parsed_episode': parsedEpisode,
      if (mediaType != null) 'media_type': mediaType,
      if (explicitTmdbId != null) 'explicit_tmdb_id': explicitTmdbId,
      if (movieTmdbId != null) 'movie_tmdb_id': movieTmdbId,
      if (tvShowTmdbId != null) 'tv_show_tmdb_id': tvShowTmdbId,
      if (episodeKey != null) 'episode_key': episodeKey,
      if (metadataMatchStatus != null) 'metadata_match_status': metadataMatchStatus,
      if (size != null) 'size': size,
      if (container != null) 'container': container,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (videoCodec != null) 'video_codec': videoCodec,
      if (audioCodec != null) 'audio_codec': audioCodec,
      if (audioChannels != null) 'audio_channels': audioChannels,
      if (isHdr != null) 'is_hdr': isHdr,
      if (hdrFormat != null) 'hdr_format': hdrFormat,
      if (versionLabel != null) 'version_label': versionLabel,
      if (duration != null) 'duration': duration,
      if (position != null) 'position': position,
      if (watchStatus != null) 'watch_status': watchStatus,
      if (lastWatchedAt != null) 'last_watched_at': lastWatchedAt,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  MediaFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? sourceId,
    Value<String>? path,
    Value<String>? fileName,
    Value<String>? parsedTitle,
    Value<int?>? parsedYear,
    Value<int?>? parsedSeason,
    Value<int?>? parsedEpisode,
    Value<String>? mediaType,
    Value<String?>? explicitTmdbId,
    Value<String?>? movieTmdbId,
    Value<String?>? tvShowTmdbId,
    Value<String?>? episodeKey,
    Value<String>? metadataMatchStatus,
    Value<int>? size,
    Value<String?>? container,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? videoCodec,
    Value<String?>? audioCodec,
    Value<String?>? audioChannels,
    Value<bool>? isHdr,
    Value<String?>? hdrFormat,
    Value<String?>? versionLabel,
    Value<int>? duration,
    Value<int>? position,
    Value<String>? watchStatus,
    Value<DateTime?>? lastWatchedAt,
    Value<bool>? isFavorite,
    Value<DateTime>? addedAt,
  }) {
    return MediaFilesCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      parsedTitle: parsedTitle ?? this.parsedTitle,
      parsedYear: parsedYear ?? this.parsedYear,
      parsedSeason: parsedSeason ?? this.parsedSeason,
      parsedEpisode: parsedEpisode ?? this.parsedEpisode,
      mediaType: mediaType ?? this.mediaType,
      explicitTmdbId: explicitTmdbId ?? this.explicitTmdbId,
      movieTmdbId: movieTmdbId ?? this.movieTmdbId,
      tvShowTmdbId: tvShowTmdbId ?? this.tvShowTmdbId,
      episodeKey: episodeKey ?? this.episodeKey,
      metadataMatchStatus: metadataMatchStatus ?? this.metadataMatchStatus,
      size: size ?? this.size,
      container: container ?? this.container,
      width: width ?? this.width,
      height: height ?? this.height,
      videoCodec: videoCodec ?? this.videoCodec,
      audioCodec: audioCodec ?? this.audioCodec,
      audioChannels: audioChannels ?? this.audioChannels,
      isHdr: isHdr ?? this.isHdr,
      hdrFormat: hdrFormat ?? this.hdrFormat,
      versionLabel: versionLabel ?? this.versionLabel,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      watchStatus: watchStatus ?? this.watchStatus,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (parsedTitle.present) {
      map['parsed_title'] = Variable<String>(parsedTitle.value);
    }
    if (parsedYear.present) {
      map['parsed_year'] = Variable<int>(parsedYear.value);
    }
    if (parsedSeason.present) {
      map['parsed_season'] = Variable<int>(parsedSeason.value);
    }
    if (parsedEpisode.present) {
      map['parsed_episode'] = Variable<int>(parsedEpisode.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (explicitTmdbId.present) {
      map['explicit_tmdb_id'] = Variable<String>(explicitTmdbId.value);
    }
    if (movieTmdbId.present) {
      map['movie_tmdb_id'] = Variable<String>(movieTmdbId.value);
    }
    if (tvShowTmdbId.present) {
      map['tv_show_tmdb_id'] = Variable<String>(tvShowTmdbId.value);
    }
    if (episodeKey.present) {
      map['episode_key'] = Variable<String>(episodeKey.value);
    }
    if (metadataMatchStatus.present) {
      map['metadata_match_status'] = Variable<String>(metadataMatchStatus.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (container.present) {
      map['container'] = Variable<String>(container.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (videoCodec.present) {
      map['video_codec'] = Variable<String>(videoCodec.value);
    }
    if (audioCodec.present) {
      map['audio_codec'] = Variable<String>(audioCodec.value);
    }
    if (audioChannels.present) {
      map['audio_channels'] = Variable<String>(audioChannels.value);
    }
    if (isHdr.present) {
      map['is_hdr'] = Variable<bool>(isHdr.value);
    }
    if (hdrFormat.present) {
      map['hdr_format'] = Variable<String>(hdrFormat.value);
    }
    if (versionLabel.present) {
      map['version_label'] = Variable<String>(versionLabel.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (watchStatus.present) {
      map['watch_status'] = Variable<String>(watchStatus.value);
    }
    if (lastWatchedAt.present) {
      map['last_watched_at'] = Variable<DateTime>(lastWatchedAt.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFilesCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('path: $path, ')
          ..write('fileName: $fileName, ')
          ..write('parsedTitle: $parsedTitle, ')
          ..write('parsedYear: $parsedYear, ')
          ..write('parsedSeason: $parsedSeason, ')
          ..write('parsedEpisode: $parsedEpisode, ')
          ..write('mediaType: $mediaType, ')
          ..write('explicitTmdbId: $explicitTmdbId, ')
          ..write('movieTmdbId: $movieTmdbId, ')
          ..write('tvShowTmdbId: $tvShowTmdbId, ')
          ..write('episodeKey: $episodeKey, ')
          ..write('metadataMatchStatus: $metadataMatchStatus, ')
          ..write('size: $size, ')
          ..write('container: $container, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('videoCodec: $videoCodec, ')
          ..write('audioCodec: $audioCodec, ')
          ..write('audioChannels: $audioChannels, ')
          ..write('isHdr: $isHdr, ')
          ..write('hdrFormat: $hdrFormat, ')
          ..write('versionLabel: $versionLabel, ')
          ..write('duration: $duration, ')
          ..write('position: $position, ')
          ..write('watchStatus: $watchStatus, ')
          ..write('lastWatchedAt: $lastWatchedAt, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TVShowsTable tVShows = $TVShowsTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final Episodes episodes = Episodes(this);
  late final $StorageSourcesTable storageSources = $StorageSourcesTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final MediaFiles mediaFiles = MediaFiles(this);
  late final Index mediaFilesMovieAddedIdx = Index(
    'media_files_movie_added_idx',
    'CREATE INDEX media_files_movie_added_idx ON media_files (movie_tmdb_id, added_at)',
  );
  late final Index mediaFilesShowOrderIdx = Index(
    'media_files_show_order_idx',
    'CREATE INDEX media_files_show_order_idx ON media_files (tv_show_tmdb_id, parsed_season, parsed_episode, path)',
  );
  late final Index mediaFilesEpisodeKeyIdx = Index(
    'media_files_episode_key_idx',
    'CREATE INDEX media_files_episode_key_idx ON media_files (episode_key)',
  );
  late final Index mediaFilesWatchStatusIdx = Index(
    'media_files_watch_status_idx',
    'CREATE INDEX media_files_watch_status_idx ON media_files (watch_status)',
  );
  late final Index mediaFilesLastWatchedAtIdx = Index(
    'media_files_last_watched_at_idx',
    'CREATE INDEX media_files_last_watched_at_idx ON media_files (last_watched_at)',
  );
  late final Index mediaFilesIsFavoriteIdx = Index(
    'media_files_is_favorite_idx',
    'CREATE INDEX media_files_is_favorite_idx ON media_files (is_favorite)',
  );
  late final Index mediaFilesAddedAtIdx = Index(
    'media_files_added_at_idx',
    'CREATE INDEX media_files_added_at_idx ON media_files (added_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tVShows,
    seasons,
    episodes,
    storageSources,
    movies,
    mediaFiles,
    mediaFilesMovieAddedIdx,
    mediaFilesShowOrderIdx,
    mediaFilesEpisodeKeyIdx,
    mediaFilesWatchStatusIdx,
    mediaFilesLastWatchedAtIdx,
    mediaFilesIsFavoriteIdx,
    mediaFilesAddedAtIdx,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('t_v_shows', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('seasons', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('storage_sources', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('media_files', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TVShowsTableCreateCompanionBuilder =
    TVShowsCompanion Function({
      required String tmdbId,
      required String title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> firstAirDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      required double rating,
      required String genres,
      required String cast,
      Value<String?> status,
      Value<int?> numberOfSeasons,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });
typedef $$TVShowsTableUpdateCompanionBuilder =
    TVShowsCompanion Function({
      Value<String> tmdbId,
      Value<String> title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> firstAirDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      Value<double> rating,
      Value<String> genres,
      Value<String> cast,
      Value<String?> status,
      Value<int?> numberOfSeasons,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });

final class $$TVShowsTableReferences extends BaseReferences<_$AppDatabase, $TVShowsTable, TVShowDO> {
  $$TVShowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SeasonsTable, List<SeasonDO>> _seasonsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.seasons, aliasName: 't_v_shows__tmdb_id__seasons__tv_show_tmdb_id');

  $$SeasonsTableProcessedTableManager get seasonsRefs {
    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.tvShowTmdbId.tmdbId.sqlEquals($_itemColumn<String>('tmdb_id')!));

    final cache = $_typedResult.readTableOrNull(_seasonsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<MediaFiles, List<MediaFileDO>> _mediaFilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.mediaFiles, aliasName: 't_v_shows__tmdb_id__media_files__tv_show_tmdb_id');

  $MediaFilesProcessedTableManager get mediaFilesRefs {
    final manager = $MediaFilesTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.tvShowTmdbId.tmdbId.sqlEquals($_itemColumn<String>('tmdb_id')!));

    final cache = $_typedResult.readTableOrNull(_mediaFilesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TVShowsTableFilterComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cast => $composableBuilder(column: $table.cast, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnFilters(column));

  Expression<bool> seasonsRefs(Expression<bool> Function($$SeasonsTableFilterComposer f) f) {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.tvShowTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaFilesRefs(Expression<bool> Function($MediaFilesFilterComposer f) f) {
    final $MediaFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.tvShowTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TVShowsTableOrderingComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnOrderings(column));
}

class $$TVShowsTableAnnotationComposer extends Composer<_$AppDatabase, $TVShowsTable> {
  $$TVShowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(column: $table.releaseYear, builder: (column) => column);

  GeneratedColumn<DateTime> get firstAirDate =>
      $composableBuilder(column: $table.firstAirDate, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl => $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => column);

  GeneratedColumn<double> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get genres => $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get cast => $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get numberOfSeasons =>
      $composableBuilder(column: $table.numberOfSeasons, builder: (column) => column);

  GeneratedColumn<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => column);

  Expression<T> seasonsRefs<T extends Object>(Expression<T> Function($$SeasonsTableAnnotationComposer a) f) {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.tvShowTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaFilesRefs<T extends Object>(Expression<T> Function($MediaFilesAnnotationComposer a) f) {
    final $MediaFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.tvShowTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TVShowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TVShowsTable,
          TVShowDO,
          $$TVShowsTableFilterComposer,
          $$TVShowsTableOrderingComposer,
          $$TVShowsTableAnnotationComposer,
          $$TVShowsTableCreateCompanionBuilder,
          $$TVShowsTableUpdateCompanionBuilder,
          (TVShowDO, $$TVShowsTableReferences),
          TVShowDO,
          PrefetchHooks Function({bool seasonsRefs, bool mediaFilesRefs})
        > {
  $$TVShowsTableTableManager(_$AppDatabase db, $TVShowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TVShowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TVShowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TVShowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> cast = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int?> numberOfSeasons = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TVShowsCompanion(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                firstAirDate: firstAirDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                status: status,
                numberOfSeasons: numberOfSeasons,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tmdbId,
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> firstAirDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                required double rating,
                required String genres,
                required String cast,
                Value<String?> status = const Value.absent(),
                Value<int?> numberOfSeasons = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TVShowsCompanion.insert(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                firstAirDate: firstAirDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                status: status,
                numberOfSeasons: numberOfSeasons,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$TVShowsTable, TVShowDO>(table), $$TVShowsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({seasonsRefs = false, mediaFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (seasonsRefs) db.seasons, if (mediaFilesRefs) db.mediaFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (seasonsRefs)
                    await $_getPrefetchedData<TVShowDO, $TVShowsTable, SeasonDO>(
                      currentTable: table,
                      referencedTable: $$TVShowsTableReferences._seasonsRefsTable(db),
                      managerFromTypedResult: (p0) => $$TVShowsTableReferences(db, table, p0).seasonsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tvShowTmdbId == item.tmdbId),
                      typedResults: items,
                    ),
                  if (mediaFilesRefs)
                    await $_getPrefetchedData<TVShowDO, $TVShowsTable, MediaFileDO>(
                      currentTable: table,
                      referencedTable: $$TVShowsTableReferences._mediaFilesRefsTable(db),
                      managerFromTypedResult: (p0) => $$TVShowsTableReferences(db, table, p0).mediaFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tvShowTmdbId == item.tmdbId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TVShowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TVShowsTable,
      TVShowDO,
      $$TVShowsTableFilterComposer,
      $$TVShowsTableOrderingComposer,
      $$TVShowsTableAnnotationComposer,
      $$TVShowsTableCreateCompanionBuilder,
      $$TVShowsTableUpdateCompanionBuilder,
      (TVShowDO, $$TVShowsTableReferences),
      TVShowDO,
      PrefetchHooks Function({bool seasonsRefs, bool mediaFilesRefs})
    >;
typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      required String tvShowTmdbId,
      required int seasonNumber,
      required String title,
      Value<String?> posterUrl,
      Value<String?> overview,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<String> tvShowTmdbId,
      Value<int> seasonNumber,
      Value<String> title,
      Value<String?> posterUrl,
      Value<String?> overview,
      Value<int?> numberOfEpisodes,
      Value<int> rowid,
    });

final class $$SeasonsTableReferences extends BaseReferences<_$AppDatabase, $SeasonsTable, SeasonDO> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TVShowsTable _tvShowTmdbIdTable(_$AppDatabase db) =>
      db.tVShows.createAlias('seasons__tv_show_tmdb_id__t_v_shows__tmdb_id');

  $$TVShowsTableProcessedTableManager get tvShowTmdbId {
    final $_column = $_itemColumn<String>('tv_show_tmdb_id')!;

    final manager = $$TVShowsTableTableManager($_db, $_db.tVShows).filter((f) => f.tmdbId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tvShowTmdbIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SeasonsTableFilterComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnFilters(column));

  $$TVShowsTableFilterComposer get tvShowTmdbId {
    final $$TVShowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableFilterComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableOrderingComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => ColumnOrderings(column));

  $$TVShowsTableOrderingComposer get tvShowTmdbId {
    final $$TVShowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableOrderingComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableAnnotationComposer extends Composer<_$AppDatabase, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seasonNumber => $composableBuilder(column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<int> get numberOfEpisodes =>
      $composableBuilder(column: $table.numberOfEpisodes, builder: (column) => column);

  $$TVShowsTableAnnotationComposer get tvShowTmdbId {
    final $$TVShowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableAnnotationComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeasonsTable,
          SeasonDO,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (SeasonDO, $$SeasonsTableReferences),
          SeasonDO,
          PrefetchHooks Function({bool tvShowTmdbId})
        > {
  $$SeasonsTableTableManager(_$AppDatabase db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tvShowTmdbId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion(
                tvShowTmdbId: tvShowTmdbId,
                seasonNumber: seasonNumber,
                title: title,
                posterUrl: posterUrl,
                overview: overview,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tvShowTmdbId,
                required int seasonNumber,
                required String title,
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> numberOfEpisodes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeasonsCompanion.insert(
                tvShowTmdbId: tvShowTmdbId,
                seasonNumber: seasonNumber,
                title: title,
                posterUrl: posterUrl,
                overview: overview,
                numberOfEpisodes: numberOfEpisodes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$SeasonsTable, SeasonDO>(table), $$SeasonsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({tvShowTmdbId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tvShowTmdbId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tvShowTmdbId,
                                referencedTable: $$SeasonsTableReferences._tvShowTmdbIdTable(db),
                                referencedColumn: $$SeasonsTableReferences._tvShowTmdbIdTable(db).tmdbId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeasonsTable,
      SeasonDO,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (SeasonDO, $$SeasonsTableReferences),
      SeasonDO,
      PrefetchHooks Function({bool tvShowTmdbId})
    >;
typedef $EpisodesCreateCompanionBuilder =
    EpisodesCompanion Function({
      required String episodeKey,
      required String tvShowTmdbId,
      required int seasonNumber,
      Value<String?> tmdbId,
      required int episodeNumber,
      required String title,
      Value<DateTime?> airDate,
      Value<String?> overview,
      Value<String?> stillUrl,
      required String guestStars,
      Value<int> rowid,
    });
typedef $EpisodesUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<String> episodeKey,
      Value<String> tvShowTmdbId,
      Value<int> seasonNumber,
      Value<String?> tmdbId,
      Value<int> episodeNumber,
      Value<String> title,
      Value<DateTime?> airDate,
      Value<String?> overview,
      Value<String?> stillUrl,
      Value<String> guestStars,
      Value<int> rowid,
    });

class $EpisodesFilterComposer extends Composer<_$AppDatabase, Episodes> {
  $EpisodesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get episodeKey =>
      $composableBuilder(column: $table.episodeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get stillUrl =>
      $composableBuilder(column: $table.stillUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get guestStars =>
      $composableBuilder(column: $table.guestStars, builder: (column) => ColumnFilters(column));
}

class $EpisodesOrderingComposer extends Composer<_$AppDatabase, Episodes> {
  $EpisodesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get episodeKey =>
      $composableBuilder(column: $table.episodeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonNumber =>
      $composableBuilder(column: $table.seasonNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get airDate =>
      $composableBuilder(column: $table.airDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get stillUrl =>
      $composableBuilder(column: $table.stillUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get guestStars =>
      $composableBuilder(column: $table.guestStars, builder: (column) => ColumnOrderings(column));
}

class $EpisodesAnnotationComposer extends Composer<_$AppDatabase, Episodes> {
  $EpisodesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get episodeKey => $composableBuilder(column: $table.episodeKey, builder: (column) => column);

  GeneratedColumn<String> get tvShowTmdbId =>
      $composableBuilder(column: $table.tvShowTmdbId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(column: $table.seasonNumber, builder: (column) => column);

  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get episodeNumber =>
      $composableBuilder(column: $table.episodeNumber, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get airDate => $composableBuilder(column: $table.airDate, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get stillUrl => $composableBuilder(column: $table.stillUrl, builder: (column) => column);

  GeneratedColumn<String> get guestStars => $composableBuilder(column: $table.guestStars, builder: (column) => column);
}

class $EpisodesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Episodes,
          EpisodeDO,
          $EpisodesFilterComposer,
          $EpisodesOrderingComposer,
          $EpisodesAnnotationComposer,
          $EpisodesCreateCompanionBuilder,
          $EpisodesUpdateCompanionBuilder,
          (EpisodeDO, BaseReferences<_$AppDatabase, Episodes, EpisodeDO>),
          EpisodeDO,
          PrefetchHooks Function()
        > {
  $EpisodesTableManager(_$AppDatabase db, Episodes table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $EpisodesFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $EpisodesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $EpisodesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> episodeKey = const Value.absent(),
                Value<String> tvShowTmdbId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String?> tmdbId = const Value.absent(),
                Value<int> episodeNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime?> airDate = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> stillUrl = const Value.absent(),
                Value<String> guestStars = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                episodeKey: episodeKey,
                tvShowTmdbId: tvShowTmdbId,
                seasonNumber: seasonNumber,
                tmdbId: tmdbId,
                episodeNumber: episodeNumber,
                title: title,
                airDate: airDate,
                overview: overview,
                stillUrl: stillUrl,
                guestStars: guestStars,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String episodeKey,
                required String tvShowTmdbId,
                required int seasonNumber,
                Value<String?> tmdbId = const Value.absent(),
                required int episodeNumber,
                required String title,
                Value<DateTime?> airDate = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> stillUrl = const Value.absent(),
                required String guestStars,
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                episodeKey: episodeKey,
                tvShowTmdbId: tvShowTmdbId,
                seasonNumber: seasonNumber,
                tmdbId: tmdbId,
                episodeNumber: episodeNumber,
                title: title,
                airDate: airDate,
                overview: overview,
                stillUrl: stillUrl,
                guestStars: guestStars,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Episodes, EpisodeDO>(table),
                  BaseReferences<_$AppDatabase, Episodes, EpisodeDO>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $EpisodesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Episodes,
      EpisodeDO,
      $EpisodesFilterComposer,
      $EpisodesOrderingComposer,
      $EpisodesAnnotationComposer,
      $EpisodesCreateCompanionBuilder,
      $EpisodesUpdateCompanionBuilder,
      (EpisodeDO, BaseReferences<_$AppDatabase, Episodes, EpisodeDO>),
      EpisodeDO,
      PrefetchHooks Function()
    >;
typedef $$StorageSourcesTableCreateCompanionBuilder =
    StorageSourcesCompanion Function({
      required String sourceId,
      required String name,
      required String type,
      required String endpoint,
      required String rootPath,
      required bool enabled,
      required String username,
      required String password,
      Value<int> rowid,
    });
typedef $$StorageSourcesTableUpdateCompanionBuilder =
    StorageSourcesCompanion Function({
      Value<String> sourceId,
      Value<String> name,
      Value<String> type,
      Value<String> endpoint,
      Value<String> rootPath,
      Value<bool> enabled,
      Value<String> username,
      Value<String> password,
      Value<int> rowid,
    });

final class $$StorageSourcesTableReferences
    extends BaseReferences<_$AppDatabase, $StorageSourcesTable, StorageSourceDO> {
  $$StorageSourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<MediaFiles, List<MediaFileDO>> _mediaFilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.mediaFiles, aliasName: 'storage_sources__source_id__media_files__source_id');

  $MediaFilesProcessedTableManager get mediaFilesRefs {
    final manager = $MediaFilesTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.sourceId.sourceId.sqlEquals($_itemColumn<String>('source_id')!));

    final cache = $_typedResult.readTableOrNull(_mediaFilesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$StorageSourcesTableFilterComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnFilters(column));

  Expression<bool> mediaFilesRefs(Expression<bool> Function($MediaFilesFilterComposer f) f) {
    final $MediaFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StorageSourcesTableOrderingComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rootPath =>
      $composableBuilder(column: $table.rootPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => ColumnOrderings(column));
}

class $$StorageSourcesTableAnnotationComposer extends Composer<_$AppDatabase, $StorageSourcesTable> {
  $$StorageSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceId => $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get endpoint => $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get rootPath => $composableBuilder(column: $table.rootPath, builder: (column) => column);

  GeneratedColumn<bool> get enabled => $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get username => $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password => $composableBuilder(column: $table.password, builder: (column) => column);

  Expression<T> mediaFilesRefs<T extends Object>(Expression<T> Function($MediaFilesAnnotationComposer a) f) {
    final $MediaFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StorageSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageSourcesTable,
          StorageSourceDO,
          $$StorageSourcesTableFilterComposer,
          $$StorageSourcesTableOrderingComposer,
          $$StorageSourcesTableAnnotationComposer,
          $$StorageSourcesTableCreateCompanionBuilder,
          $$StorageSourcesTableUpdateCompanionBuilder,
          (StorageSourceDO, $$StorageSourcesTableReferences),
          StorageSourceDO,
          PrefetchHooks Function({bool mediaFilesRefs})
        > {
  $$StorageSourcesTableTableManager(_$AppDatabase db, $StorageSourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StorageSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StorageSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StorageSourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> rootPath = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageSourcesCompanion(
                sourceId: sourceId,
                name: name,
                type: type,
                endpoint: endpoint,
                rootPath: rootPath,
                enabled: enabled,
                username: username,
                password: password,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceId,
                required String name,
                required String type,
                required String endpoint,
                required String rootPath,
                required bool enabled,
                required String username,
                required String password,
                Value<int> rowid = const Value.absent(),
              }) => StorageSourcesCompanion.insert(
                sourceId: sourceId,
                name: name,
                type: type,
                endpoint: endpoint,
                rootPath: rootPath,
                enabled: enabled,
                username: username,
                password: password,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StorageSourcesTable, StorageSourceDO>(table),
                  $$StorageSourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaFilesRefs) db.mediaFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaFilesRefs)
                    await $_getPrefetchedData<StorageSourceDO, $StorageSourcesTable, MediaFileDO>(
                      currentTable: table,
                      referencedTable: $$StorageSourcesTableReferences._mediaFilesRefsTable(db),
                      managerFromTypedResult: (p0) => $$StorageSourcesTableReferences(db, table, p0).mediaFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sourceId == item.sourceId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StorageSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageSourcesTable,
      StorageSourceDO,
      $$StorageSourcesTableFilterComposer,
      $$StorageSourcesTableOrderingComposer,
      $$StorageSourcesTableAnnotationComposer,
      $$StorageSourcesTableCreateCompanionBuilder,
      $$StorageSourcesTableUpdateCompanionBuilder,
      (StorageSourceDO, $$StorageSourcesTableReferences),
      StorageSourceDO,
      PrefetchHooks Function({bool mediaFilesRefs})
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      required String tmdbId,
      required String title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> releaseDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      required double rating,
      required String genres,
      required String cast,
      Value<int> rowid,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<String> tmdbId,
      Value<String> title,
      Value<String?> originalTitle,
      Value<int?> releaseYear,
      Value<DateTime?> releaseDate,
      Value<String?> posterUrl,
      Value<String?> backdropUrl,
      Value<String?> logoUrl,
      Value<String?> overview,
      Value<String?> certification,
      Value<double> rating,
      Value<String> genres,
      Value<String> cast,
      Value<int> rowid,
    });

final class $$MoviesTableReferences extends BaseReferences<_$AppDatabase, $MoviesTable, MovieDO> {
  $$MoviesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<MediaFiles, List<MediaFileDO>> _mediaFilesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.mediaFiles, aliasName: 'movies__tmdb_id__media_files__movie_tmdb_id');

  $MediaFilesProcessedTableManager get mediaFilesRefs {
    final manager = $MediaFilesTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.movieTmdbId.tmdbId.sqlEquals($_itemColumn<String>('tmdb_id')!));

    final cache = $_typedResult.readTableOrNull(_mediaFilesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MoviesTableFilterComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cast => $composableBuilder(column: $table.cast, builder: (column) => ColumnFilters(column));

  Expression<bool> mediaFilesRefs(Expression<bool> Function($MediaFilesFilterComposer f) f) {
    final $MediaFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.movieTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MoviesTableOrderingComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get releaseYear =>
      $composableBuilder(column: $table.releaseYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => ColumnOrderings(column));
}

class $$MoviesTableAnnotationComposer extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tmdbId => $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => column);

  GeneratedColumn<int> get releaseYear => $composableBuilder(column: $table.releaseYear, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<String> get posterUrl => $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get backdropUrl =>
      $composableBuilder(column: $table.backdropUrl, builder: (column) => column);

  GeneratedColumn<String> get logoUrl => $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<String> get overview => $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get certification =>
      $composableBuilder(column: $table.certification, builder: (column) => column);

  GeneratedColumn<double> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get genres => $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get cast => $composableBuilder(column: $table.cast, builder: (column) => column);

  Expression<T> mediaFilesRefs<T extends Object>(Expression<T> Function($MediaFilesAnnotationComposer a) f) {
    final $MediaFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tmdbId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.movieTmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $MediaFilesAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          MovieDO,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (MovieDO, $$MoviesTableReferences),
          MovieDO,
          PrefetchHooks Function({bool mediaFilesRefs})
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<String> genres = const Value.absent(),
                Value<String> cast = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                releaseDate: releaseDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tmdbId,
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String?> backdropUrl = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> certification = const Value.absent(),
                required double rating,
                required String genres,
                required String cast,
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion.insert(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                releaseYear: releaseYear,
                releaseDate: releaseDate,
                posterUrl: posterUrl,
                backdropUrl: backdropUrl,
                logoUrl: logoUrl,
                overview: overview,
                certification: certification,
                rating: rating,
                genres: genres,
                cast: cast,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$MoviesTable, MovieDO>(table), $$MoviesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({mediaFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mediaFilesRefs) db.mediaFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mediaFilesRefs)
                    await $_getPrefetchedData<MovieDO, $MoviesTable, MediaFileDO>(
                      currentTable: table,
                      referencedTable: $$MoviesTableReferences._mediaFilesRefsTable(db),
                      managerFromTypedResult: (p0) => $$MoviesTableReferences(db, table, p0).mediaFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.movieTmdbId == item.tmdbId),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      MovieDO,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (MovieDO, $$MoviesTableReferences),
      MovieDO,
      PrefetchHooks Function({bool mediaFilesRefs})
    >;
typedef $MediaFilesCreateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      required String sourceId,
      required String path,
      required String fileName,
      required String parsedTitle,
      Value<int?> parsedYear,
      Value<int?> parsedSeason,
      Value<int?> parsedEpisode,
      required String mediaType,
      Value<String?> explicitTmdbId,
      Value<String?> movieTmdbId,
      Value<String?> tvShowTmdbId,
      Value<String?> episodeKey,
      required String metadataMatchStatus,
      required int size,
      Value<String?> container,
      Value<int?> width,
      Value<int?> height,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> audioChannels,
      required bool isHdr,
      Value<String?> hdrFormat,
      Value<String?> versionLabel,
      required int duration,
      required int position,
      required String watchStatus,
      Value<DateTime?> lastWatchedAt,
      required bool isFavorite,
      required DateTime addedAt,
    });
typedef $MediaFilesUpdateCompanionBuilder =
    MediaFilesCompanion Function({
      Value<int> id,
      Value<String> sourceId,
      Value<String> path,
      Value<String> fileName,
      Value<String> parsedTitle,
      Value<int?> parsedYear,
      Value<int?> parsedSeason,
      Value<int?> parsedEpisode,
      Value<String> mediaType,
      Value<String?> explicitTmdbId,
      Value<String?> movieTmdbId,
      Value<String?> tvShowTmdbId,
      Value<String?> episodeKey,
      Value<String> metadataMatchStatus,
      Value<int> size,
      Value<String?> container,
      Value<int?> width,
      Value<int?> height,
      Value<String?> videoCodec,
      Value<String?> audioCodec,
      Value<String?> audioChannels,
      Value<bool> isHdr,
      Value<String?> hdrFormat,
      Value<String?> versionLabel,
      Value<int> duration,
      Value<int> position,
      Value<String> watchStatus,
      Value<DateTime?> lastWatchedAt,
      Value<bool> isFavorite,
      Value<DateTime> addedAt,
    });

final class $MediaFilesReferences extends BaseReferences<_$AppDatabase, MediaFiles, MediaFileDO> {
  $MediaFilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StorageSourcesTable _sourceIdTable(_$AppDatabase db) =>
      db.storageSources.createAlias('media_files__source_id__storage_sources__source_id');

  $$StorageSourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<String>('source_id')!;

    final manager = $$StorageSourcesTableTableManager(
      $_db,
      $_db.storageSources,
    ).filter((f) => f.sourceId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $MoviesTable _movieTmdbIdTable(_$AppDatabase db) =>
      db.movies.createAlias('media_files__movie_tmdb_id__movies__tmdb_id');

  $$MoviesTableProcessedTableManager? get movieTmdbId {
    final $_column = $_itemColumn<String>('movie_tmdb_id');
    if ($_column == null) return null;
    final manager = $$MoviesTableTableManager($_db, $_db.movies).filter((f) => f.tmdbId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_movieTmdbIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $TVShowsTable _tvShowTmdbIdTable(_$AppDatabase db) =>
      db.tVShows.createAlias('media_files__tv_show_tmdb_id__t_v_shows__tmdb_id');

  $$TVShowsTableProcessedTableManager? get tvShowTmdbId {
    final $_column = $_itemColumn<String>('tv_show_tmdb_id');
    if ($_column == null) return null;
    final manager = $$TVShowsTableTableManager($_db, $_db.tVShows).filter((f) => f.tmdbId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tvShowTmdbIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $MediaFilesFilterComposer extends Composer<_$AppDatabase, MediaFiles> {
  $MediaFilesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedYear =>
      $composableBuilder(column: $table.parsedYear, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedSeason =>
      $composableBuilder(column: $table.parsedSeason, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get episodeKey =>
      $composableBuilder(column: $table.episodeKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadataMatchStatus =>
      $composableBuilder(column: $table.metadataMatchStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get videoCodec =>
      $composableBuilder(column: $table.videoCodec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioCodec =>
      $composableBuilder(column: $table.audioCodec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHdr => $composableBuilder(column: $table.isHdr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hdrFormat =>
      $composableBuilder(column: $table.hdrFormat, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite =>
      $composableBuilder(column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnFilters(column));

  $$StorageSourcesTableFilterComposer get sourceId {
    final $$StorageSourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.storageSources,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StorageSourcesTableFilterComposer(
            $db: $db,
            $table: $db.storageSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableFilterComposer get movieTmdbId {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieTmdbId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TVShowsTableFilterComposer get tvShowTmdbId {
    final $$TVShowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableFilterComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MediaFilesOrderingComposer extends Composer<_$AppDatabase, MediaFiles> {
  $MediaFilesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedYear =>
      $composableBuilder(column: $table.parsedYear, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedSeason =>
      $composableBuilder(column: $table.parsedSeason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get episodeKey =>
      $composableBuilder(column: $table.episodeKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadataMatchStatus =>
      $composableBuilder(column: $table.metadataMatchStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get container =>
      $composableBuilder(column: $table.container, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get videoCodec =>
      $composableBuilder(column: $table.videoCodec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioCodec =>
      $composableBuilder(column: $table.audioCodec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHdr =>
      $composableBuilder(column: $table.isHdr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hdrFormat =>
      $composableBuilder(column: $table.hdrFormat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite =>
      $composableBuilder(column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => ColumnOrderings(column));

  $$StorageSourcesTableOrderingComposer get sourceId {
    final $$StorageSourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.storageSources,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StorageSourcesTableOrderingComposer(
            $db: $db,
            $table: $db.storageSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableOrderingComposer get movieTmdbId {
    final $$MoviesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieTmdbId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MoviesTableOrderingComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TVShowsTableOrderingComposer get tvShowTmdbId {
    final $$TVShowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableOrderingComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MediaFilesAnnotationComposer extends Composer<_$AppDatabase, MediaFiles> {
  $MediaFilesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path => $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get fileName => $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get parsedTitle =>
      $composableBuilder(column: $table.parsedTitle, builder: (column) => column);

  GeneratedColumn<int> get parsedYear => $composableBuilder(column: $table.parsedYear, builder: (column) => column);

  GeneratedColumn<int> get parsedSeason => $composableBuilder(column: $table.parsedSeason, builder: (column) => column);

  GeneratedColumn<int> get parsedEpisode =>
      $composableBuilder(column: $table.parsedEpisode, builder: (column) => column);

  GeneratedColumn<String> get mediaType => $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get explicitTmdbId =>
      $composableBuilder(column: $table.explicitTmdbId, builder: (column) => column);

  GeneratedColumn<String> get episodeKey => $composableBuilder(column: $table.episodeKey, builder: (column) => column);

  GeneratedColumn<String> get metadataMatchStatus =>
      $composableBuilder(column: $table.metadataMatchStatus, builder: (column) => column);

  GeneratedColumn<int> get size => $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<String> get container => $composableBuilder(column: $table.container, builder: (column) => column);

  GeneratedColumn<int> get width => $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height => $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get videoCodec => $composableBuilder(column: $table.videoCodec, builder: (column) => column);

  GeneratedColumn<String> get audioCodec => $composableBuilder(column: $table.audioCodec, builder: (column) => column);

  GeneratedColumn<String> get audioChannels =>
      $composableBuilder(column: $table.audioChannels, builder: (column) => column);

  GeneratedColumn<bool> get isHdr => $composableBuilder(column: $table.isHdr, builder: (column) => column);

  GeneratedColumn<String> get hdrFormat => $composableBuilder(column: $table.hdrFormat, builder: (column) => column);

  GeneratedColumn<String> get versionLabel =>
      $composableBuilder(column: $table.versionLabel, builder: (column) => column);

  GeneratedColumn<int> get duration => $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get watchStatus =>
      $composableBuilder(column: $table.watchStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get lastWatchedAt =>
      $composableBuilder(column: $table.lastWatchedAt, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt => $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$StorageSourcesTableAnnotationComposer get sourceId {
    final $$StorageSourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.storageSources,
      getReferencedColumn: (t) => t.sourceId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$StorageSourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.storageSources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MoviesTableAnnotationComposer get movieTmdbId {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.movieTmdbId,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TVShowsTableAnnotationComposer get tvShowTmdbId {
    final $$TVShowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tvShowTmdbId,
      referencedTable: $db.tVShows,
      getReferencedColumn: (t) => t.tmdbId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TVShowsTableAnnotationComposer(
            $db: $db,
            $table: $db.tVShows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $MediaFilesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          MediaFiles,
          MediaFileDO,
          $MediaFilesFilterComposer,
          $MediaFilesOrderingComposer,
          $MediaFilesAnnotationComposer,
          $MediaFilesCreateCompanionBuilder,
          $MediaFilesUpdateCompanionBuilder,
          (MediaFileDO, $MediaFilesReferences),
          MediaFileDO,
          PrefetchHooks Function({bool sourceId, bool movieTmdbId, bool tvShowTmdbId})
        > {
  $MediaFilesTableManager(_$AppDatabase db, MediaFiles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $MediaFilesFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $MediaFilesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $MediaFilesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> parsedTitle = const Value.absent(),
                Value<int?> parsedYear = const Value.absent(),
                Value<int?> parsedSeason = const Value.absent(),
                Value<int?> parsedEpisode = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String?> explicitTmdbId = const Value.absent(),
                Value<String?> movieTmdbId = const Value.absent(),
                Value<String?> tvShowTmdbId = const Value.absent(),
                Value<String?> episodeKey = const Value.absent(),
                Value<String> metadataMatchStatus = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<String?> container = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                Value<bool> isHdr = const Value.absent(),
                Value<String?> hdrFormat = const Value.absent(),
                Value<String?> versionLabel = const Value.absent(),
                Value<int> duration = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> watchStatus = const Value.absent(),
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => MediaFilesCompanion(
                id: id,
                sourceId: sourceId,
                path: path,
                fileName: fileName,
                parsedTitle: parsedTitle,
                parsedYear: parsedYear,
                parsedSeason: parsedSeason,
                parsedEpisode: parsedEpisode,
                mediaType: mediaType,
                explicitTmdbId: explicitTmdbId,
                movieTmdbId: movieTmdbId,
                tvShowTmdbId: tvShowTmdbId,
                episodeKey: episodeKey,
                metadataMatchStatus: metadataMatchStatus,
                size: size,
                container: container,
                width: width,
                height: height,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                audioChannels: audioChannels,
                isHdr: isHdr,
                hdrFormat: hdrFormat,
                versionLabel: versionLabel,
                duration: duration,
                position: position,
                watchStatus: watchStatus,
                lastWatchedAt: lastWatchedAt,
                isFavorite: isFavorite,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sourceId,
                required String path,
                required String fileName,
                required String parsedTitle,
                Value<int?> parsedYear = const Value.absent(),
                Value<int?> parsedSeason = const Value.absent(),
                Value<int?> parsedEpisode = const Value.absent(),
                required String mediaType,
                Value<String?> explicitTmdbId = const Value.absent(),
                Value<String?> movieTmdbId = const Value.absent(),
                Value<String?> tvShowTmdbId = const Value.absent(),
                Value<String?> episodeKey = const Value.absent(),
                required String metadataMatchStatus,
                required int size,
                Value<String?> container = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> videoCodec = const Value.absent(),
                Value<String?> audioCodec = const Value.absent(),
                Value<String?> audioChannels = const Value.absent(),
                required bool isHdr,
                Value<String?> hdrFormat = const Value.absent(),
                Value<String?> versionLabel = const Value.absent(),
                required int duration,
                required int position,
                required String watchStatus,
                Value<DateTime?> lastWatchedAt = const Value.absent(),
                required bool isFavorite,
                required DateTime addedAt,
              }) => MediaFilesCompanion.insert(
                id: id,
                sourceId: sourceId,
                path: path,
                fileName: fileName,
                parsedTitle: parsedTitle,
                parsedYear: parsedYear,
                parsedSeason: parsedSeason,
                parsedEpisode: parsedEpisode,
                mediaType: mediaType,
                explicitTmdbId: explicitTmdbId,
                movieTmdbId: movieTmdbId,
                tvShowTmdbId: tvShowTmdbId,
                episodeKey: episodeKey,
                metadataMatchStatus: metadataMatchStatus,
                size: size,
                container: container,
                width: width,
                height: height,
                videoCodec: videoCodec,
                audioCodec: audioCodec,
                audioChannels: audioChannels,
                isHdr: isHdr,
                hdrFormat: hdrFormat,
                versionLabel: versionLabel,
                duration: duration,
                position: position,
                watchStatus: watchStatus,
                lastWatchedAt: lastWatchedAt,
                isFavorite: isFavorite,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<MediaFiles, MediaFileDO>(table), $MediaFilesReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({sourceId = false, movieTmdbId = false, tvShowTmdbId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sourceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sourceId,
                                referencedTable: $MediaFilesReferences._sourceIdTable(db),
                                referencedColumn: $MediaFilesReferences._sourceIdTable(db).sourceId,
                              )
                              as T;
                    }
                    if (movieTmdbId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.movieTmdbId,
                                referencedTable: $MediaFilesReferences._movieTmdbIdTable(db),
                                referencedColumn: $MediaFilesReferences._movieTmdbIdTable(db).tmdbId,
                              )
                              as T;
                    }
                    if (tvShowTmdbId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tvShowTmdbId,
                                referencedTable: $MediaFilesReferences._tvShowTmdbIdTable(db),
                                referencedColumn: $MediaFilesReferences._tvShowTmdbIdTable(db).tmdbId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $MediaFilesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      MediaFiles,
      MediaFileDO,
      $MediaFilesFilterComposer,
      $MediaFilesOrderingComposer,
      $MediaFilesAnnotationComposer,
      $MediaFilesCreateCompanionBuilder,
      $MediaFilesUpdateCompanionBuilder,
      (MediaFileDO, $MediaFilesReferences),
      MediaFileDO,
      PrefetchHooks Function({bool sourceId, bool movieTmdbId, bool tvShowTmdbId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TVShowsTableTableManager get tVShows => $$TVShowsTableTableManager(_db, _db.tVShows);
  $$SeasonsTableTableManager get seasons => $$SeasonsTableTableManager(_db, _db.seasons);
  $EpisodesTableManager get episodes => $EpisodesTableManager(_db, _db.episodes);
  $$StorageSourcesTableTableManager get storageSources => $$StorageSourcesTableTableManager(_db, _db.storageSources);
  $$MoviesTableTableManager get movies => $$MoviesTableTableManager(_db, _db.movies);
  $MediaFilesTableManager get mediaFiles => $MediaFilesTableManager(_db, _db.mediaFiles);
}
