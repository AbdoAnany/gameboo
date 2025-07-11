import 'package:equatable/equatable.dart';

enum RankTier { bronze, silver, gold, platinum, diamond, master, grandmaster }

enum BadgeType {
  // Achievement badges
  firstWin,
  perfectGame,
  speedRunner,
  strategist,
  unstoppable,

  // Progress badges
  rookie,
  veteran,
  expert,
  legend,

  // Game-specific badges
  rockPaperScissorsMaster,
  ticTacToeChampion,
  memoryGenius,
  sharpshooter,
  racingChampion,
  pilotAce,
  quizMaster,
  ballBlasterPro,
  towerArchitect,

  // Special badges
  dailyStreak,
  weeklyChampion,
  allRounder,
  perfectionist,
}

class UserLevel extends Equatable {
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final int totalXP;
  final RankTier rank;
  final String rankTitle;

  const UserLevel({
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.totalXP,
    required this.rank,
    required this.rankTitle,
  });

  UserLevel copyWith({
    int? level,
    int? currentXP,
    int? xpToNextLevel,
    int? totalXP,
    RankTier? rank,
    String? rankTitle,
  }) {
    return UserLevel(
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      totalXP: totalXP ?? this.totalXP,
      rank: rank ?? this.rank,
      rankTitle: rankTitle ?? this.rankTitle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'currentXP': currentXP,
      'xpToNextLevel': xpToNextLevel,
      'totalXP': totalXP,
      'rank': rank.name,
      'rankTitle': rankTitle,
    };
  }

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      level: json['level'] ?? 1,
      currentXP: json['currentXP'] ?? 0,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      totalXP: json['totalXP'] ?? 0,
      rank: RankTier.values.firstWhere(
        (e) => e.name == json['rank'],
        orElse: () => RankTier.bronze,
      ),
      rankTitle: json['rankTitle'] ?? 'Rookie',
    );
  }

  @override
  List<Object?> get props => [
    level,
    currentXP,
    xpToNextLevel,
    totalXP,
    rank,
    rankTitle,
  ];
}

class Badge extends Equatable {
  final BadgeType type;
  final String name;
  final String description;
  final String iconPath;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final Map<String, dynamic> requirements;
  final int xpReward;

  const Badge({
    required this.type,
    required this.name,
    required this.description,
    required this.iconPath,
    this.isUnlocked = false,
    this.unlockedAt,
    this.requirements = const {},
    this.xpReward = 0,
  });

  Badge copyWith({
    BadgeType? type,
    String? name,
    String? description,
    String? iconPath,
    bool? isUnlocked,
    DateTime? unlockedAt,
    Map<String, dynamic>? requirements,
    int? xpReward,
  }) {
    return Badge(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      requirements: requirements ?? this.requirements,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
      'requirements': requirements,
      'xpReward': xpReward,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BadgeType.firstWin,
      ),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'])
          : null,
      requirements: Map<String, dynamic>.from(json['requirements'] ?? {}),
      xpReward: json['xpReward'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    type,
    name,
    description,
    iconPath,
    isUnlocked,
    unlockedAt,
    requirements,
    xpReward,
  ];
}

class DailyChallenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final BadgeType? requiredBadge;
  final int targetScore;
  final int xpReward;
  final bool isCompleted;
  final DateTime expiresAt;
  final Map<String, dynamic> challengeData;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    this.requiredBadge,
    required this.targetScore,
    required this.xpReward,
    this.isCompleted = false,
    required this.expiresAt,
    this.challengeData = const {},
  });

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    BadgeType? requiredBadge,
    int? targetScore,
    int? xpReward,
    bool? isCompleted,
    DateTime? expiresAt,
    Map<String, dynamic>? challengeData,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      requiredBadge: requiredBadge ?? this.requiredBadge,
      targetScore: targetScore ?? this.targetScore,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
      expiresAt: expiresAt ?? this.expiresAt,
      challengeData: challengeData ?? this.challengeData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requiredBadge': requiredBadge?.name,
      'targetScore': targetScore,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'challengeData': challengeData,
    };
  }

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      requiredBadge: json['requiredBadge'] != null
          ? BadgeType.values.firstWhere(
              (e) => e.name == json['requiredBadge'],
              orElse: () => BadgeType.firstWin,
            )
          : null,
      targetScore: json['targetScore'] ?? 0,
      xpReward: json['xpReward'] ?? 0,
      isCompleted: json['isCompleted'] ?? false,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        json['expiresAt'] ??
            DateTime.now().add(Duration(days: 1)).millisecondsSinceEpoch,
      ),
      challengeData: Map<String, dynamic>.from(json['challengeData'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    requiredBadge,
    targetScore,
    xpReward,
    isCompleted,
    expiresAt,
    challengeData,
  ];
}

class UserProgress extends Equatable {
  final String userId;
  final UserLevel level;
  final List<Badge> badges;
  final List<DailyChallenge> dailyChallenges;
  final int dailyStreak;
  final int longestStreak;
  final DateTime lastPlayedAt;
  final Map<String, int> gameStats; // gameType -> highScore
  final Map<String, int> gamePlayCounts; // gameType -> playCount

  const UserProgress({
    required this.userId,
    required this.level,
    this.badges = const [],
    this.dailyChallenges = const [],
    this.dailyStreak = 0,
    this.longestStreak = 0,
    required this.lastPlayedAt,
    this.gameStats = const {},
    this.gamePlayCounts = const {},
  });

  UserProgress copyWith({
    String? userId,
    UserLevel? level,
    List<Badge>? badges,
    List<DailyChallenge>? dailyChallenges,
    int? dailyStreak,
    int? longestStreak,
    DateTime? lastPlayedAt,
    Map<String, int>? gameStats,
    Map<String, int>? gamePlayCounts,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      badges: badges ?? this.badges,
      dailyChallenges: dailyChallenges ?? this.dailyChallenges,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      gameStats: gameStats ?? this.gameStats,
      gamePlayCounts: gamePlayCounts ?? this.gamePlayCounts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level.toJson(),
      'badges': badges.map((badge) => badge.toJson()).toList(),
      'dailyChallenges': dailyChallenges
          .map((challenge) => challenge.toJson())
          .toList(),
      'dailyStreak': dailyStreak,
      'longestStreak': longestStreak,
      'lastPlayedAt': lastPlayedAt.millisecondsSinceEpoch,
      'gameStats': gameStats,
      'gamePlayCounts': gamePlayCounts,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] ?? '',
      level: UserLevel.fromJson(json['level'] ?? {}),
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((badgeJson) => Badge.fromJson(badgeJson))
              .toList() ??
          [],
      dailyChallenges:
          (json['dailyChallenges'] as List<dynamic>?)
              ?.map((challengeJson) => DailyChallenge.fromJson(challengeJson))
              .toList() ??
          [],
      dailyStreak: json['dailyStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(
        json['lastPlayedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      gameStats: Map<String, int>.from(json['gameStats'] ?? {}),
      gamePlayCounts: Map<String, int>.from(json['gamePlayCounts'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
    userId,
    level,
    badges,
    dailyChallenges,
    dailyStreak,
    longestStreak,
    lastPlayedAt,
    gameStats,
    gamePlayCounts,
  ];
}

class ProgressionRepository {
  static int calculateXPForLevel(int level) {
    // XP required increases by 100 each level
    return 100 + (level - 1) * 50;
  }

  static UserLevel calculateLevelFromXP(int totalXP) {
    int level = 1;
    int xpForCurrentLevel = 0;

    while (xpForCurrentLevel + calculateXPForLevel(level) <= totalXP) {
      xpForCurrentLevel += calculateXPForLevel(level);
      level++;
    }

    final currentXP = totalXP - xpForCurrentLevel;
    final xpToNextLevel = calculateXPForLevel(level) - currentXP;
    final rank = _getRankForLevel(level);
    final rankTitle = _getRankTitle(rank, level);

    return UserLevel(
      level: level,
      currentXP: currentXP,
      xpToNextLevel: xpToNextLevel,
      totalXP: totalXP,
      rank: rank,
      rankTitle: rankTitle,
    );
  }

  static RankTier _getRankForLevel(int level) {
    if (level >= 50) return RankTier.grandmaster;
    if (level >= 40) return RankTier.master;
    if (level >= 30) return RankTier.diamond;
    if (level >= 20) return RankTier.platinum;
    if (level >= 10) return RankTier.gold;
    if (level >= 5) return RankTier.silver;
    return RankTier.bronze;
  }

  static String _getRankTitle(RankTier rank, int level) {
    switch (rank) {
      case RankTier.bronze:
        return 'Rookie';
      case RankTier.silver:
        return 'Amateur';
      case RankTier.gold:
        return 'Professional';
      case RankTier.platinum:
        return 'Expert';
      case RankTier.diamond:
        return 'Master';
      case RankTier.master:
        return 'Champion';
      case RankTier.grandmaster:
        return 'Legend';
    }
  }

  static int calculateGameXP(int score, int difficulty, bool isWin) {
    int baseXP = 10;
    int scoreBonus = (score / 100).floor() * 5;
    int difficultyMultiplier = difficulty + 1;
    int winBonus = isWin ? 25 : 5;

    return (baseXP + scoreBonus) * difficultyMultiplier + winBonus;
  }

  static List<Badge> getDefaultBadges() {
    return [
      Badge(
        type: BadgeType.firstWin,
        name: 'First Victory',
        description: 'Win your first game',
        iconPath: 'assets/images/badges/first_win.png',
        requirements: {'wins': 1},
        xpReward: 50,
      ),
      Badge(
        type: BadgeType.perfectGame,
        name: 'Perfect Game',
        description: 'Complete a game with perfect score',
        iconPath: 'assets/images/badges/perfect_game.png',
        requirements: {'perfectGames': 1},
        xpReward: 100,
      ),
      Badge(
        type: BadgeType.speedRunner,
        name: 'Speed Runner',
        description: 'Complete a game in record time',
        iconPath: 'assets/images/badges/speed_runner.png',
        requirements: {'fastCompletions': 5},
        xpReward: 75,
      ),
      Badge(
        type: BadgeType.dailyStreak,
        name: 'Daily Player',
        description: 'Play for 7 consecutive days',
        iconPath: 'assets/images/badges/daily_streak.png',
        requirements: {'consecutiveDays': 7},
        xpReward: 200,
      ),
      Badge(
        type: BadgeType.allRounder,
        name: 'All Rounder',
        description: 'Play all available games',
        iconPath: 'assets/images/badges/all_rounder.png',
        requirements: {'gamesPlayed': 9},
        xpReward: 300,
      ),
      // Game-specific badges
      Badge(
        type: BadgeType.rockPaperScissorsMaster,
        name: 'RPS Master',
        description: 'Win 10 Rock Paper Scissors games',
        iconPath: 'assets/images/badges/rps_master.png',
        requirements: {'rockPaperScissorsWins': 10},
        xpReward: 100,
      ),
      Badge(
        type: BadgeType.ticTacToeChampion,
        name: 'Tic Tac Toe Champion',
        description: 'Win 15 Tic Tac Toe games',
        iconPath: 'assets/images/badges/ttt_champion.png',
        requirements: {'ticTacToeWins': 15},
        xpReward: 125,
      ),
      Badge(
        type: BadgeType.memoryGenius,
        name: 'Memory Genius',
        description: 'Complete memory game in under 30 seconds',
        iconPath: 'assets/images/badges/memory_genius.png',
        requirements: {'memoryFastTime': 30},
        xpReward: 150,
      ),
    ];
  }
}
