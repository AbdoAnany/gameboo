import 'package:equatable/equatable.dart';
import '../../../characters/domain/entities/character.dart';

enum BadgeType { bronze, silver, gold, diamond }

enum BadgeCategory { games, social, achievements, special }

class Badge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final BadgeType type;
  final BadgeCategory category;
  final int xpReward;
  final bool isEarned;
  final DateTime? earnedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.type,
    required this.category,
    required this.xpReward,
    this.isEarned = false,
    this.earnedAt,
  });

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    BadgeType? type,
    BadgeCategory? category,
    int? xpReward,
    bool? isEarned,
    DateTime? earnedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'type': type.name,
      'category': category.name,
      'xpReward': xpReward,
      'isEarned': isEarned,
      'earnedAt': earnedAt?.millisecondsSinceEpoch,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BadgeType.bronze,
      ),
      category: BadgeCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BadgeCategory.games,
      ),
      xpReward: json['xpReward'] ?? 0,
      isEarned: json['isEarned'] ?? false,
      earnedAt: json['earnedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['earnedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imagePath,
    type,
    category,
    xpReward,
    isEarned,
    earnedAt,
  ];
}

class UserProfile extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? country;
  final String? rank;

  final int xp;
  final int level;
  final CharacterType selectedCharacter;
  final List<Badge> badges;
  final Map<String, int> gameStats;
  final int streak;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Shop/Wallet related fields
  final int coins;
  final int gems;
  final List<String> ownedShopItems;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.country,
    this.rank = 'Bronze',
    this.xp = 0,
    this.level = 1,
    this.selectedCharacter = CharacterType.nova,
    this.badges = const [],
    this.gameStats = const {},
    this.streak = 0,
    this.lastPlayedAt,
    required this.createdAt,
    required this.updatedAt,
    this.coins = 1000,
    this.gems = 50,
    this.ownedShopItems = const [],
  });

  // Progressive XP calculation: Level 1 = 1000 XP, Level 2 = 2200 XP, Level 3 = 3600 XP, etc.
  int get xpForCurrentLevel {
    if (level <= 1) return 0;
    return (level - 1) * 1000 + ((level - 2).clamp(0, level - 2)) * 200;
  }

  int get xpForNextLevel {
    return (level * 1000) + ((level - 1) * 200);
  }

  int get xpToNextLevel {
    return xpForNextLevel - xp;
  }

  double get levelProgress {
    final prevLevelXP = _calculateLevelXP(level - 1);
    final thisLevelXP = _calculateLevelXP(level);
    return (xp - prevLevelXP) / (thisLevelXP - prevLevelXP);
  }

  // Helper for progressive XP
  int _calculateLevelXP(int level) {
    if (level <= 1) return 0;
    return (level * 1000) + ((level - 1) * 200);
  }

  int get totalWins {
    return gameStats.values.fold(0, (sum, wins) => sum + wins);
  }

  List<Badge> get earnedBadges {
    return badges.where((badge) => badge.isEarned).toList();
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? country,
    String? rank,
    int? xp,
    int? level,
    CharacterType? selectedCharacter,
    List<Badge>? badges,
    Map<String, int>? gameStats,
    int? streak,
    DateTime? lastPlayedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? coins,
    int? gems,
    List<String>? ownedShopItems,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      rank: rank ?? this.rank,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      badges: badges ?? this.badges,
      gameStats: gameStats ?? this.gameStats,
      streak: streak ?? this.streak,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      ownedShopItems: ownedShopItems ?? this.ownedShopItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'country': country,
      'xp': xp,
      'level': level,
      'rank': rank,
      'selectedCharacter': selectedCharacter.name,
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'gameStats': gameStats,
      'streak': streak,
      'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'coins': coins,
      'gems': gems,
      'ownedShopItems': ownedShopItems,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      country: json['country'],
      xp: json['xp'] ?? 0,
      rank: json['rank'],
      level: json['level'] ?? 1,
      selectedCharacter: CharacterType.values.firstWhere(
        (e) => e.name == json['selectedCharacter'],
        orElse: () => CharacterType.nova,
      ),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((badgeJson) => Badge.fromJson(badgeJson))
          .toList(),
      gameStats: Map<String, int>.from(json['gameStats'] ?? {}),
      streak: json['streak'] ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      coins: json['coins'] ?? 1000,
      gems: json['gems'] ?? 50,
      ownedShopItems: List<String>.from(json['ownedShopItems'] ?? []),
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    avatarUrl,
    country,
    xp,
    level,
    selectedCharacter,
    badges,
    gameStats,
    streak,
    rank,
    lastPlayedAt,
    createdAt,
    updatedAt,
    coins,
    gems,
    ownedShopItems,
  ];
}

class DailyChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final String gameType;
  final Map<String, dynamic> requirements;
  final int xpReward;
  final bool isCompleted;
  final DateTime date;
  final DateTime? completedAt;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.gameType,
    required this.requirements,
    required this.xpReward,
    this.isCompleted = false,
    required this.date,
    this.completedAt,
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? gameType,
    Map<String, dynamic>? requirements,
    int? xpReward,
    bool? isCompleted,
    DateTime? date,
    DateTime? completedAt,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      requirements: requirements ?? this.requirements,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'gameType': gameType,
      'requirements': requirements,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'date': date.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      gameType: json['gameType'] ?? '',
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      xpReward: json['xpReward'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      date: DateTime.fromMillisecondsSinceEpoch(
        json['date'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    gameType,
    requirements,
    xpReward,
    isCompleted,
    date,
    completedAt,
  ];
}
