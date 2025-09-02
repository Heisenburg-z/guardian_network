class AppUser {
  final String id;
  final String? email;
  final String displayName;
  final DateTime joinDate;
  final bool isVerified;
  final int contributionScore;

  AppUser({
    required this.id,
    this.email,
    required this.displayName,
    required this.joinDate,
    this.isVerified = false,
    this.contributionScore = 0,
  });

  // Anonymous user factory
  factory AppUser.anonymous() {
    return AppUser(
      id: 'anonymous',
      displayName: 'Community Member',
      joinDate: DateTime.now(),
      isVerified: false,
      contributionScore: 0,
    );
  }

  // For demo purposes - create random users
  factory AppUser.demo(String id) {
    final names = [
      'SafetyHero',
      'NeighborhoodWatch',
      'CommunityGuardian',
      'UrbanProtector',
      'CityDefender',
    ];
    final random = DateTime.now().millisecond % names.length;

    return AppUser(
      id: id,
      displayName: names[random],
      joinDate: DateTime.now().subtract(
        Duration(days: DateTime.now().millisecond % 30),
      ),
      isVerified: DateTime.now().millisecond % 3 == 0,
      contributionScore: DateTime.now().millisecond % 100,
    );
  }
}
