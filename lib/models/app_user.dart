class AppUser {
  final String uid;
  final String displayName;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'Movie Fan',
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'photoUrl': photoUrl,
      };
}