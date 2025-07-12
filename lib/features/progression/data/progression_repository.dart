// import '../../../core/repository/cached_repository.dart';
// import '../../../core/cache/cache_service.dart';
// import '../domain/entities/progression.dart';
// import '../../games/domain/entities/game.dart';
//
// class ProgressionRepository extends CachedRepository<UserProgress> {
//   @override
//   String get cacheKey => CacheConfig.progressionKey;
//
//   @override
//   Duration get cacheTTL => CacheConfig.progressionCacheTTL;
//
//   @override
//   Map<String, dynamic> toJson(UserProgress entity) => entity.toJson();
//
//   @override
//   UserProgress fromJson(Map<String, dynamic> json) =>
//       UserProgress.fromJson(json);
//
//   @override
//   Future<UserProgress> fetchFromRemote() async {
//     // Simulate API call - replace with actual Firebase/API calls
//     await Future.delayed(const Duration(milliseconds: 400));
//
//     // Return mock progression data
//     return UserProgress(
//       userId: 'default_user',
//       level: const UserLevel(
//         level: 5,
//         currentXP: 1250,
//         xpToNextLevel: 350,
//         totalXP: 1250,
//         rank: RankTier.silver,
//         rankTitle: 'Silver Warrior',
//       ),
//       badges: _getDefaultBadges(),
//       dailyChallenges: _getDefaultDailyChallenges(),
//       dailyStreak: 4,
//       longestStreak: 8,
//       lastPlayedAt: DateTime.now().subtract(const Duration(hours: 2)),
//       gameStats: {
//         'rock_paper_scissors': 850,
//         'tic_tac_toe': 1200,
//         'memory_game': 650,
//       },
//       gamePlayCounts: {
//         'rock_paper_scissors': 25,
//         'tic_tac_toe': 18,
//         'memory_game': 12,
//       },
//     );
//   }
//
//   @override
//   Future<void> updateRemote(UserProgress data) async {
//     // Implement Firebase/API update
//     await Future.delayed(const Duration(milliseconds: 300));
//     // TODO: Update Firestore document
//   }
//
//   /// Record XP gain and update level
//   Future<UserProgress> recordXPGain(int xpGained, String source) async {
//     final currentProgress = await getData();
//     final newXp = currentProgress.level.currentXP + xpGained;
//     final newTotalXp = currentProgress.level.totalXP + xpGained;
//     final newLevel = _calculateLevel(newTotalXp);
//
//     final updatedUserLevel = currentProgress.level.copyWith(
//       currentXP: newXp,
//       level: newLevel,
//       totalXP: newTotalXp,
//       xpToNextLevel: _calculateXpToNextLevel(newXp, newLevel),
//       rank: _calculateRank(newLevel),
//       rankTitle: _getRankTitle(_calculateRank(newLevel)),
//     );
//
//     final updatedProgress = currentProgress.copyWith(
//       level: updatedUserLevel,
//       lastPlayedAt: DateTime.now(),
//     );
//
//     return await updateData(updatedProgress);
//   }
//
//   /// Unlock a badge
//   Future<UserProgress> unlockBadge(BadgeType badgeType) async {
//     final currentProgress = await getData();
//     final badges = List<Badge>.from(currentProgress.badges);
//
//     final badgeIndex = badges.indexWhere((b) => b.type == badgeType);
//     if (badgeIndex != -1 && !badges[badgeIndex].isUnlocked) {
//       badges[badgeIndex] = badges[badgeIndex].copyWith(
//         isUnlocked: true,
//         unlockedAt: DateTime.now(),
//       );
//
//       final updatedProgress = currentProgress.copyWith(
//         badges: badges,
//         lastPlayedAt: DateTime.now(),
//       );
//
//       return await updateData(updatedProgress);
//     }
//
//     return currentProgress;
//   }
//
//   /// Complete a daily challenge
//   Future<UserProgress> completeDailyChallenge(String challengeId) async {
//     final currentProgress = await getData();
//     final challenges = List<DailyChallenge>.from(
//       currentProgress.dailyChallenges,
//     );
//
//     final challengeIndex = challenges.indexWhere((c) => c.id == challengeId);
//     if (challengeIndex != -1 && !challenges[challengeIndex].isCompleted) {
//       challenges[challengeIndex] = challenges[challengeIndex].copyWith(
//         isCompleted: true,
//       );
//
//       final updatedProgress = currentProgress.copyWith(
//         dailyChallenges: challenges,
//         lastPlayedAt: DateTime.now(),
//       );
//
//       return await updateData(updatedProgress);
//     }
//
//     return currentProgress;
//   }
//
//   /// Update game statistics
//   Future<UserProgress> updateGameStats(String gameType, int score) async {
//     final currentProgress = await getData();
//     final gameStats = Map<String, int>.from(currentProgress.gameStats);
//     final gamePlayCounts = Map<String, int>.from(
//       currentProgress.gamePlayCounts,
//     );
//
//     // Update high score if this score is better
//     if (score > (gameStats[gameType] ?? 0)) {
//       gameStats[gameType] = score;
//     }
//
//     // Increment play count
//     gamePlayCounts[gameType] = (gamePlayCounts[gameType] ?? 0) + 1;
//
//     final updatedProgress = currentProgress.copyWith(
//       gameStats: gameStats,
//       gamePlayCounts: gamePlayCounts,
//       lastPlayedAt: DateTime.now(),
//     );
//
//     return await updateData(updatedProgress);
//   }
//
//   /// Record game play and update streak
//   Future<UserProgress> recordGamePlay(GameType gameType, bool won) async {
//     final currentProgress = await getData();
//
//     // Update streak
//     final newDailyStreak = won ? currentProgress.dailyStreak + 1 : 0;
//
//     final newLongestStreak = newDailyStreak > currentProgress.longestStreak
//         ? newDailyStreak
//         : currentProgress.longestStreak;
//
//     final updatedProgress = currentProgress.copyWith(
//       dailyStreak: newDailyStreak,
//       longestStreak: newLongestStreak,
//       lastPlayedAt: DateTime.now(),
//     );
//
//     return await updateData(updatedProgress);
//   }
//
//   /// Calculate level from total XP
//   int _calculateLevel(int totalXp) {
//     // Progressive leveling: 1000 XP for level 1, then +200 XP per level
//     if (totalXp < 1000) return 1;
//     return ((totalXp - 1000) / 200).floor() + 2;
//   }
//
//   /// Calculate XP needed for next level
//   int _calculateXpToNextLevel(int currentXp, int currentLevel) {
//     final xpForNextLevel = currentLevel == 1
//         ? 1000
//         : 1000 + (currentLevel - 1) * 200;
//     return xpForNextLevel - currentXp;
//   }
//
//   /// Calculate rank based on level
//   RankTier _calculateRank(int level) {
//     if (level >= 50) return RankTier.diamond;
//     if (level >= 25) return RankTier.gold;
//     if (level >= 10) return RankTier.silver;
//     return RankTier.bronze;
//   }
//
//   /// Get rank title
//   String _getRankTitle(RankTier rank) {
//     switch (rank) {
//       case RankTier.bronze:
//         return 'Bronze Rookie';
//       case RankTier.silver:
//         return 'Silver Warrior';
//       case RankTier.gold:
//         return 'Gold Champion';
//       case RankTier.diamond:
//         return 'Diamond Master';
//       case RankTier.platinum:
//         return 'Platinum Elite';
//       case RankTier.master:
//         return 'Grand Master';
//       case RankTier.grandmaster:
//         return 'Legendary Grandmaster';
//     }
//   }
//
//   /// Get default badges
//   static List<Badge> _getDefaultBadges() {
//     return [
//       const Badge(
//         type: BadgeType.firstWin,
//         name: 'First Victory',
//         description: 'Win your first game',
//         iconPath: 'assets/images/badges/first_win.png',
//         isUnlocked: true,
//         xpReward: 50,
//       ),
//       const Badge(
//         type: BadgeType.dailyStreak,
//         name: 'Daily Streak',
//         description: 'Play for 5 consecutive days',
//         iconPath: 'assets/images/badges/daily_streak.png',
//         isUnlocked: false,
//         xpReward: 200,
//       ),
//       const Badge(
//         type: BadgeType.perfectGame,
//         name: 'Perfect Game',
//         description: 'Complete a game with perfect score',
//         iconPath: 'assets/images/badges/perfect_game.png',
//         isUnlocked: false,
//         xpReward: 150,
//       ),
//     ];
//   }
//
//   /// Get default daily challenges
//   static List<DailyChallenge> _getDefaultDailyChallenges() {
//     final today = DateTime.now();
//     final tomorrow = today.add(const Duration(days: 1));
//     return [
//       DailyChallenge(
//         id: 'daily_win_${today.millisecondsSinceEpoch}',
//         title: 'Victory Dance',
//         description: 'Win 3 games today',
//         targetScore: 3,
//         xpReward: 100,
//         expiresAt: tomorrow,
//         isCompleted: false,
//       ),
//       DailyChallenge(
//         id: 'daily_rps_${today.millisecondsSinceEpoch}',
//         title: 'Rock Paper Scissors Master',
//         description: 'Score 500+ in Rock Paper Scissors',
//         targetScore: 500,
//         xpReward: 75,
//         expiresAt: tomorrow,
//         isCompleted: false,
//         requiredBadge: BadgeType.rockPaperScissorsMaster,
//       ),
//       DailyChallenge(
//         id: 'daily_streak_${today.millisecondsSinceEpoch}',
//         title: 'Streak Builder',
//         description: 'Maintain a 3-game win streak',
//         targetScore: 3,
//         xpReward: 150,
//         expiresAt: tomorrow,
//         isCompleted: false,
//       ),
//     ];
//   }
// }
