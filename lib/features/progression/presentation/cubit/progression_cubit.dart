import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/progression.dart';
import '../../../games/domain/entities/game.dart';

abstract class ProgressionState extends Equatable {
  const ProgressionState();
}

class ProgressionInitial extends ProgressionState {
  @override
  List<Object> get props => [];
}

class ProgressionLoading extends ProgressionState {
  @override
  List<Object> get props => [];
}

class ProgressionLoaded extends ProgressionState {
  final UserProgress userProgress;

  const ProgressionLoaded(this.userProgress);

  @override
  List<Object> get props => [userProgress];
}

class ProgressionError extends ProgressionState {
  final String message;

  const ProgressionError(this.message);

  @override
  List<Object> get props => [message];
}

class ProgressionCubit extends Cubit<ProgressionState> {
  UserProgress? _currentProgress;

  ProgressionCubit() : super(ProgressionInitial());

  UserProgress? get currentProgress => _currentProgress;

  void initializeProgress(String userId) {
    emit(ProgressionLoading());

    try {
      // Create initial progress for new user
      _currentProgress = UserProgress(
        userId: userId,
        level: ProgressionRepository.calculateLevelFromXP(0),
        badges: ProgressionRepository.getDefaultBadges(),
        lastPlayedAt: DateTime.now(),
      );

      emit(ProgressionLoaded(_currentProgress!));
    } catch (e) {
      emit(ProgressionError('Failed to initialize progress: $e'));
    }
  }

  void loadProgress(Map<String, dynamic> progressData) {
    emit(ProgressionLoading());

    try {
      _currentProgress = UserProgress.fromJson(progressData);
      emit(ProgressionLoaded(_currentProgress!));
    } catch (e) {
      emit(ProgressionError('Failed to load progress: $e'));
    }
  }

  void addXP(int xpToAdd, {String? source}) {
    if (_currentProgress == null) return;

    final newTotalXP = _currentProgress!.level.totalXP + xpToAdd;
    final newLevel = ProgressionRepository.calculateLevelFromXP(newTotalXP);

    // Check if level increased
    final leveledUp = newLevel.level > _currentProgress!.level.level;

    _currentProgress = _currentProgress!.copyWith(
      level: newLevel,
      lastPlayedAt: DateTime.now(),
    );

    emit(ProgressionLoaded(_currentProgress!));

    if (leveledUp) {
      _checkForLevelBadges(newLevel.level);
    }
  }

  void completeGame(GameSession session) {
    if (_currentProgress == null) return;

    final gameTypeString = session.gameType.name;
    final isWin = session.status == GameStatus.completed;

    // Calculate XP earned
    final xpEarned = ProgressionRepository.calculateGameXP(
      session.score,
      session.difficulty.index,
      isWin,
    );

    // Update game statistics
    final newGameStats = Map<String, int>.from(_currentProgress!.gameStats);
    final currentHighScore = newGameStats[gameTypeString] ?? 0;
    if (session.score > currentHighScore) {
      newGameStats[gameTypeString] = session.score;
    }

    final newGamePlayCounts = Map<String, int>.from(
      _currentProgress!.gamePlayCounts,
    );
    newGamePlayCounts[gameTypeString] =
        (newGamePlayCounts[gameTypeString] ?? 0) + 1;

    // Update daily streak
    final now = DateTime.now();
    final lastPlayed = _currentProgress!.lastPlayedAt;
    final daysDifference = now.difference(lastPlayed).inDays;

    int newDailyStreak = _currentProgress!.dailyStreak;
    int newLongestStreak = _currentProgress!.longestStreak;

    if (daysDifference == 1) {
      // Played yesterday, continue streak
      newDailyStreak++;
    } else if (daysDifference == 0) {
      // Played today already, keep current streak
      newDailyStreak = _currentProgress!.dailyStreak;
    } else {
      // Missed days, reset streak
      newDailyStreak = 1;
    }

    if (newDailyStreak > newLongestStreak) {
      newLongestStreak = newDailyStreak;
    }

    _currentProgress = _currentProgress!.copyWith(
      gameStats: newGameStats,
      gamePlayCounts: newGamePlayCounts,
      dailyStreak: newDailyStreak,
      longestStreak: newLongestStreak,
      lastPlayedAt: now,
    );

    // Add XP and check for badges
    addXP(xpEarned, source: 'Game completion');
    _checkForGameBadges(session);
    _checkForStreakBadges();
  }

  void _checkForLevelBadges(int newLevel) {
    if (_currentProgress == null) return;

    // Check for level-based badges
    final badges = List<Badge>.from(_currentProgress!.badges);
    bool badgesUpdated = false;

    for (int i = 0; i < badges.length; i++) {
      final badge = badges[i];
      if (badge.isUnlocked) continue;

      // Check rookie badge (level 5)
      if (badge.type == BadgeType.rookie && newLevel >= 5) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }
      // Check veteran badge (level 15)
      else if (badge.type == BadgeType.veteran && newLevel >= 15) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }
      // Check expert badge (level 25)
      else if (badge.type == BadgeType.expert && newLevel >= 25) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }
      // Check legend badge (level 50)
      else if (badge.type == BadgeType.legend && newLevel >= 50) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }
    }

    if (badgesUpdated) {
      _currentProgress = _currentProgress!.copyWith(badges: badges);
      emit(ProgressionLoaded(_currentProgress!));
    }
  }

  void _checkForGameBadges(GameSession session) {
    if (_currentProgress == null) return;

    final badges = List<Badge>.from(_currentProgress!.badges);
    final gameStats = _currentProgress!.gameStats;
    final gamePlayCounts = _currentProgress!.gamePlayCounts;
    bool badgesUpdated = false;

    for (int i = 0; i < badges.length; i++) {
      final badge = badges[i];
      if (badge.isUnlocked) continue;

      // Check first win badge
      if (badge.type == BadgeType.firstWin &&
          session.status == GameStatus.completed) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }

      // Check game-specific badges
      if (session.gameType == GameType.rockPaperScissors) {
        final wins = _getWinsForGame(GameType.rockPaperScissors);
        if (badge.type == BadgeType.rockPaperScissorsMaster && wins >= 10) {
          badges[i] = badge.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          badgesUpdated = true;
        }
      }

      // Check all rounder badge
      if (badge.type == BadgeType.allRounder) {
        final uniqueGamesPlayed = gamePlayCounts.keys.length;
        if (uniqueGamesPlayed >= 9) {
          // All 9 games
          badges[i] = badge.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
          );
          badgesUpdated = true;
        }
      }
    }

    if (badgesUpdated) {
      _currentProgress = _currentProgress!.copyWith(badges: badges);
      emit(ProgressionLoaded(_currentProgress!));
    }
  }

  void _checkForStreakBadges() {
    if (_currentProgress == null) return;

    final badges = List<Badge>.from(_currentProgress!.badges);
    bool badgesUpdated = false;

    for (int i = 0; i < badges.length; i++) {
      final badge = badges[i];
      if (badge.isUnlocked) continue;

      // Check daily streak badge
      if (badge.type == BadgeType.dailyStreak &&
          _currentProgress!.dailyStreak >= 7) {
        badges[i] = badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
        badgesUpdated = true;
      }
    }

    if (badgesUpdated) {
      _currentProgress = _currentProgress!.copyWith(badges: badges);
      emit(ProgressionLoaded(_currentProgress!));
    }
  }

  int _getWinsForGame(GameType gameType) {
    // This would typically come from a more detailed game history
    // For now, we'll estimate based on play count and assume 50% win rate
    final playCount = _currentProgress!.gamePlayCounts[gameType.name] ?? 0;
    return (playCount * 0.5).floor();
  }

  List<Badge> getUnlockedBadges() {
    if (_currentProgress == null) return [];
    return _currentProgress!.badges.where((badge) => badge.isUnlocked).toList();
  }

  List<Badge> getLockedBadges() {
    if (_currentProgress == null) return [];
    return _currentProgress!.badges
        .where((badge) => !badge.isUnlocked)
        .toList();
  }

  double getProgressToNextLevel() {
    if (_currentProgress == null) return 0.0;
    final level = _currentProgress!.level;
    final totalXPForLevel = level.currentXP + level.xpToNextLevel;
    return level.currentXP / totalXPForLevel;
  }

  Map<String, dynamic> getProgressData() {
    if (_currentProgress == null) return {};
    return _currentProgress!.toJson();
  }

  void resetProgress() {
    _currentProgress = null;
    emit(ProgressionInitial());
  }
}
