import 'dart:math' as math;
import '../../../core/repository/cached_repository.dart';
import '../../../core/cache/cache_service.dart';
import '../domain/entities/user_profile.dart';
import '../../characters/domain/entities/character.dart';

class ProfileRepository extends CachedRepository<UserProfile> {
  @override
  String get cacheKey => CacheConfig.profileKey;

  @override
  Duration get cacheTTL => CacheConfig.profileCacheTTL;

  @override
  Map<String, dynamic> toJson(UserProfile entity) => entity.toJson();

  @override
  UserProfile fromJson(Map<String, dynamic> json) => UserProfile.fromJson(json);

  @override
  Future<UserProfile> fetchFromRemote() async {
    // Simulate API call - replace with actual Firebase/API calls
    await Future.delayed(const Duration(milliseconds: 500));
    // Return mock user profile data  from cache
    UserProfile currentProfile = await getData();
    if (currentProfile != null) {
      return currentProfile;
    }
     currentProfile = UserProfile(
      id: 'default_user',
      username: 'Player1',
      coins: 1000,
      gems: 50,
      xp: 1,
      level: 0,
      rank: UserRankType.basic,
      badges:[],
      gameStats:{},
      ownedShopItems: [],
      selectedCharacter: CharacterType.blitz,
      streak: 0,
      lastPlayedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(), email: 'player@gameboo.com',
    );
      return currentProfile;



  }

  @override
  Future<void> updateRemote(UserProfile data) async {
    // Implement Firebase/API update
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Update Firestore document
  }

  /// Update XP and level
  Future<UserProfile> updateXP(int xpGained) async {
    final currentProfile = await getData();
    final newXp = currentProfile.xp + xpGained;
    final newLevel = _calculateLevel(newXp);

    final updatedProfile = currentProfile.copyWith(
      xp: newXp,
      level: newLevel,
      updatedAt: DateTime.now(),
    );

    return await updateData(updatedProfile,1);
  }

  /// Update game statistics
  Future<UserProfile> updateGameStats({
    required String gameType,
    required bool won,
  }) async {
    final currentProfile = await getData();
    final newStats = Map<String, int>.from(currentProfile.gameStats);

    // Update game-specific stats
    final gameKey = gameType.toLowerCase();
    final currentWins = newStats[gameKey] ?? 0;

    newStats[gameKey] = currentWins + (won ? 1 : 0);

    // Update overall stats
    final updatedProfile = currentProfile.copyWith(
      gameStats: newStats,
      lastPlayedAt: DateTime.now(),
      updatedAt: DateTime.now(),
      streak: won ? currentProfile.streak + 1 : 0,
    );

    return await updateData(updatedProfile,3);
  }

  /// Update selected character
  Future<UserProfile> updateSelectedCharacter(
    CharacterType characterType,
  ) async {
    final currentProfile = await getData();
    final updatedProfile = currentProfile.copyWith(
      selectedCharacter: characterType,
      updatedAt: DateTime.now(),
    );
    return await updateData(updatedProfile,2);
  }

  /// Earn new badge
  Future<UserProfile> earnBadge(Badge badge) async {
    final currentProfile = await getData();
    final badges = List<Badge>.from(currentProfile.badges);

    if (!badges.any((b) => b.id == badge.id)) {
      badges.add(badge.copyWith(isEarned: true, earnedAt: DateTime.now()));
    }

    final updatedProfile = currentProfile.copyWith(
      badges: badges,
      xp: currentProfile.xp + badge.xpReward,
      updatedAt: DateTime.now(),
    );

    return await updateData(updatedProfile,5);
  }

  /// Update coins
  Future<UserProfile> updateCoins(int amount) async {
    final currentProfile = await getData();
    final updatedProfile = currentProfile.copyWith(
      coins: (currentProfile.coins + amount).clamp(0, double.maxFinite.toInt()),
      updatedAt: DateTime.now(),
    );
    return await updateData(updatedProfile,4);
  }

  /// Update gems
  Future<UserProfile> updateGems(int amount) async {
    final currentProfile = await getData();
    final updatedProfile = currentProfile.copyWith(
      gems: (currentProfile.gems + amount).clamp(0, double.maxFinite.toInt()),
      updatedAt: DateTime.now(),
    );
    return await updateData(updatedProfile,6);
  }

  /// Add shop item to owned items
  Future<UserProfile> addOwnedItem(String itemId) async {
    final currentProfile = await getData();
    final ownedItems = List<String>.from(currentProfile.ownedShopItems);

    if (!ownedItems.contains(itemId)) {
      ownedItems.add(itemId);
    }

    final updatedProfile = currentProfile.copyWith(
      ownedShopItems: ownedItems,
      updatedAt: DateTime.now(),
    );

    return await updateData(updatedProfile,6);
  }

  /// Calculate level from XP
  int _calculateLevel(int xp) {
    // Level calculation: level = floor(sqrt(xp / 100)) + 1
    return math.sqrt(xp / 100).floor() + 1;
  }

  /// Get default badges
  static List<Badge> _getDefaultBadges() {
    return [
      const Badge(
        id: 'first_win',
        name: 'First Victory',
        description: 'Win your first game',
        imagePath: 'assets/images/badges/first_win.png',
        type: BadgeType.bronze,
        category: BadgeCategory.achievements,
        xpReward: 50,
        isEarned: true,
      ),
      const Badge(
        id: 'quick_learner',
        name: 'Quick Learner',
        description: 'Reach level 5',
        imagePath: 'assets/images/badges/quick_learner.png',
        type: BadgeType.silver,
        category: BadgeCategory.achievements,
        xpReward: 100,
        isEarned: true,
      ),
    ];
  }

  /// Get default game statistics
  static Map<String, int> _getDefaultGameStats() {
    return {
      'rock_paper_scissors': 0,
      'tic_tac_toe': 0,
      'memory_cards': 0,
      'shooting_game': 0,
    };
  }
}
