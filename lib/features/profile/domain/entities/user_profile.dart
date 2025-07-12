// xp_utils.dart
import 'package:equatable/equatable.dart';

import '/features/characters/domain/entities/character.dart';
import '/features/profile/domain/entities/game_activity.dart';

int calculateLevelXP(int level) {
  if (level <= 1) return 1000;
  int xp = 1000;
  for (int i = 2; i <= level; i++) {
    xp += 1000 + (i - 1) * 200;
  }
  return xp;
}

int xpRequiredForLevel(int level) {
  return calculateLevelXP(level) - calculateLevelXP(level - 1);
}

double calculateLevelProgress(int xp, int level) {
  final prevXP = calculateLevelXP(level - 1);
  final nextXP = calculateLevelXP(level);
  return (xp - prevXP) / (nextXP - prevXP);
}

class LevelProgressModel {
  final int currentLevel;
  final int totalXP;
  final int previousLevelXP;
  final int nextLevelXP;
  final double progressPercent;

  LevelProgressModel({
    required this.currentLevel,
    required this.totalXP,
    required this.previousLevelXP,
    required this.nextLevelXP,
    required this.progressPercent,
  });

  factory LevelProgressModel.fromXP(int xp, int level) {
    final previousXP = calculateLevelXP(level - 1);
    final nextXP = calculateLevelXP(level);
    final progress = ((xp - previousXP) / (nextXP - previousXP))
        .clamp(0, 1)
        .toDouble();

    return LevelProgressModel(
      currentLevel: level,
      totalXP: xp,
      previousLevelXP: previousXP,
      nextLevelXP: nextXP,
      progressPercent: progress,
    );
  }
}

// badge.dart
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

  Map<String, dynamic> toJson() => {
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

// Enum to map badge assets
enum UserRankType { basic, advance, pro, premium }

String getBadgeAsset(UserRankType type) {
  switch (type) {
    case UserRankType.basic:
      return 'assets/images/badge/level-basic.png';
    case UserRankType.advance:
      return 'assets/images/badge/level-advance.png';
    case UserRankType.pro:
      return 'assets/images/badge/level-pro.png';
    case UserRankType.premium:
      return 'assets/images/badge/level-premium.png';
  }
}

// user_profile.dart
class UserProfile extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? country;
  final UserRankType rank;
  final int xp;
  final int level;
  final CharacterType selectedCharacter;
  final List<Badge> badges;
  final Map<String, int> gameStats;
  final int streak;
  final DateTime? lastPlayedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int coins;
  final int gems;
  final List<String> ownedShopItems;
  final List<GameActivity> activityHistory;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.country,
    this.rank = UserRankType.basic,
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
    this.activityHistory = const [],
  });

  double get levelProgress => calculateLevelProgress(xp, level);
  int get xpToNextLevel => calculateLevelXP(level + 1) - xp;
  int get xpForCurrentLevel => xpRequiredForLevel(level);
  int get totalWins => gameStats.values.fold(0, (sum, e) => sum + e);
  List<Badge> get earnedBadges => badges.where((e) => e.isEarned).toList();
  LevelProgressModel get progressModel => LevelProgressModel.fromXP(xp, level);

  //copyWith
  UserProfile copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? country,
    UserRankType? rank,
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
    List<GameActivity>? activityHistory,
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
      activityHistory: activityHistory ?? this.activityHistory,
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
    activityHistory,
  ];
  //fromJson
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      country: json['country'],
      rank: UserRankType.values.firstWhere(
        (e) => e.name == json['rank'],
        orElse: () => UserRankType.basic,
      ),
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      selectedCharacter: CharacterType.values.firstWhere(
        (e) => e.name == json['selectedCharacter'],
        orElse: () => CharacterType.nova,
      ),
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => Badge.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      gameStats: Map<String, int>.from(json['gameStats'] ?? {}),
      streak: json['streak'] ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt'])
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      coins: json['coins'] ?? 1000,
      gems: json['gems'] ?? 50,
      ownedShopItems: List<String>.from(json['ownedShopItems'] ?? const []),
      activityHistory:
          (json['activityHistory'] as List<dynamic>?)
              ?.map((e) => GameActivity.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }
  // toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'country': country,
      'rank': rank.name,
      'xp': xp,
      'level': level,
      'selectedCharacter': selectedCharacter.name,
      'badges': badges.map((e) => e.toJson()).toList(),
      'gameStats': gameStats,
      'streak': streak,
      'lastPlayedAt': lastPlayedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'coins': coins,
      'gems': gems,
      'ownedShopItems': ownedShopItems,
      'activityHistory': activityHistory.map((e) => e.toJson()).toList(),
    };
  }
}
