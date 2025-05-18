class Movie {
  final int id;
  final String title;
  final String posterPath;
  final double rating;
  final String? releaseDate;
  final String? overview;

  // Computed property to extract year from release date
  int? get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return null;
    try {
      return DateTime.parse(releaseDate!).year;
    } catch (e) {
      return null;
    }
  }

  const Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.rating,
    this.releaseDate,
    this.overview,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    try {
      return Movie(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? 'Unknown Title',
        posterPath: json['poster_path'] as String? ?? '',
        rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
        releaseDate: json['release_date'] as String?,
        overview: json['overview'] as String?,
      );
    } catch (e) {
      print('Error parsing movie: $e');
      // Return a fallback movie object
      return Movie(
        id: 0,
        title: 'Error Loading Movie',
        posterPath: '',
        rating: 0.0,
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'vote_average': rating,
        'release_date': releaseDate,
        'overview': overview,
      };
}
