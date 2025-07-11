import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/game_activity.dart';
import '../../../characters/domain/entities/character.dart';
import '../../data/profile_repository.dart';

// Profile States
abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;

  const ProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

// Profile Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _profileRepository = ProfileRepository();

  ProfileCubit() : super(ProfileInitial()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    emit(ProfileLoading());

    try {
      final profile = await _profileRepository.getData();
      emit(ProfileLoaded(profile));
    } catch (e) {
      emit(ProfileError('Failed to load profile: $e'));
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      final updatedProfile = await _profileRepository.updateData(profile);
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      emit(ProfileError('Failed to update profile: $e'));
    }
  }

  Future<void> addXP(int xp) async {
    if (state is ProfileLoaded) {
      try {
        final updatedProfile = await _profileRepository.updateXP(xp);
        emit(ProfileLoaded(updatedProfile));
      } catch (e) {
        emit(ProfileError('Failed to add XP: $e'));
      }
    }
  }

  Future<void> selectCharacter(CharacterType character) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final updatedProfile = currentProfile.copyWith(
          selectedCharacter: character,
          updatedAt: DateTime.now(),
        );
        final savedProfile = await _profileRepository.updateData(
          updatedProfile,
        );
        emit(ProfileLoaded(savedProfile));
      } catch (e) {
        emit(ProfileError('Failed to select character: $e'));
      }
    }
  }

  Future<void> incrementGameWin(String gameType) async {
    if (state is ProfileLoaded) {
      try {
        final updatedProfile = await _profileRepository.updateGameStats(
          gameType: gameType,
          won: true,
        );
        emit(ProfileLoaded(updatedProfile));
      } catch (e) {
        emit(ProfileError('Failed to update game stats: $e'));
      }
    }
  }

  void levelUp() {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final nextLevel = currentProfile.level + 1;
      final minXPForNextLevel = _calculateLevelXP(nextLevel - 1);
      final updatedProfile = currentProfile.copyWith(
        xp: minXPForNextLevel,
        level: nextLevel,
        updatedAt: DateTime.now(),
      );
      emit(ProfileLoaded(updatedProfile));
    }
  }

  void resetProgress() {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        xp: 0,
        level: 1,
        updatedAt: DateTime.now(),
      );

      emit(ProfileLoaded(updatedProfile));
    }
  }

  void addCoins(int amount) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        coins: currentProfile.coins + amount,
        updatedAt: DateTime.now(),
      );
      emit(ProfileLoaded(updatedProfile));
    }
  }

  void spendCoins(int amount) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      if (currentProfile.coins >= amount) {
        final updatedProfile = currentProfile.copyWith(
          coins: currentProfile.coins - amount,
          updatedAt: DateTime.now(),
        );
        emit(ProfileLoaded(updatedProfile));
      }
    }
  }

  void addGems(int amount) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        gems: currentProfile.gems + amount,
        updatedAt: DateTime.now(),
      );
      emit(ProfileLoaded(updatedProfile));
    }
  }

  void spendGems(int amount) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      if (currentProfile.gems >= amount) {
        final updatedProfile = currentProfile.copyWith(
          gems: currentProfile.gems - amount,
          updatedAt: DateTime.now(),
        );
        emit(ProfileLoaded(updatedProfile));
      }
    }
  }

  void spendXP(int amount) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      if (currentProfile.xp >= amount) {
        final updatedProfile = currentProfile.copyWith(
          xp: currentProfile.xp - amount,
          updatedAt: DateTime.now(),
        );
        emit(ProfileLoaded(updatedProfile));
      }
    }
  }

  void purchaseShopItem(String itemId) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      if (!currentProfile.ownedShopItems.contains(itemId)) {
        final updatedProfile = currentProfile.copyWith(
          ownedShopItems: [...currentProfile.ownedShopItems, itemId],
          updatedAt: DateTime.now(),
        );
        emit(ProfileLoaded(updatedProfile));
      }
    }
  }

  // Progressive XP calculation: Level 1 = 1000 XP, Level 2 = 2200 XP, Level 3 = 3600 XP, etc.
  int _calculateLevelXP(int level) {
    if (level <= 1) return 1000;
    return (level * 1000) + ((level - 1) * 200);
  }

  // Activity tracking methods
  Future<void> addGameActivity({
    required ActivityType type,
    required GameType gameType,
    required String difficulty,
    int xpEarned = 0,
    Map<String, dynamic>? metadata,
  }) async {
    print(
      '🎮 Adding game activity: $type for $gameType on $difficulty difficulty',
    );
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final activity = GameActivity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          gameType: gameType,
          title: _getActivityTitle(type, gameType, difficulty),
          description: _getActivityDescription(
            type,
            gameType,
            difficulty,
            xpEarned,
          ),
          xpEarned: xpEarned,
          metadata: {'difficulty': difficulty, ...?metadata},
          timestamp: DateTime.now(),
        );

        print(
          '📝 Created activity: ${activity.title} - ${activity.description}',
        );

        final updatedActivities = [activity, ...currentProfile.activityHistory];
        // Keep only the last 100 activities to prevent unlimited growth
        final limitedActivities = updatedActivities.take(100).toList();

        final updatedProfile = currentProfile.copyWith(
          activityHistory: limitedActivities,
          updatedAt: DateTime.now(),
        );

        print('💾 Saving profile with ${limitedActivities.length} activities');
        final savedProfile = await _profileRepository.updateData(
          updatedProfile,
        );
        emit(ProfileLoaded(savedProfile));
        print(
          '✅ Activity successfully saved! Total activities: ${savedProfile.activityHistory.length}',
        );
      } catch (e) {
        print('❌ Failed to add activity: $e');
        emit(ProfileError('Failed to add activity: $e'));
      }
    } else {
      print('⚠️ Profile not loaded, cannot add activity');
    }
  }

  String _getActivityTitle(
    ActivityType type,
    GameType gameType,
    String difficulty,
  ) {
    final gameName = ActivityHelper.getGameDisplayName(gameType);
    final difficultyName = ActivityHelper.getDifficultyDisplayName(difficulty);

    switch (type) {
      case ActivityType.gameWin:
        return '$gameName Victory';
      case ActivityType.gameLoss:
        return '$gameName Defeat';
      case ActivityType.gameDraw:
        return '$gameName Draw';
      default:
        return '$gameName Game';
    }
  }

  String _getActivityDescription(
    ActivityType type,
    GameType gameType,
    String difficulty,
    int xpEarned,
  ) {
    final gameName = ActivityHelper.getGameDisplayName(gameType);
    final difficultyName = ActivityHelper.getDifficultyDisplayName(difficulty);

    switch (type) {
      case ActivityType.gameWin:
        return 'Won $gameName on $difficultyName difficulty${xpEarned > 0 ? ' (+$xpEarned XP)' : ''}';
      case ActivityType.gameLoss:
        return 'Lost $gameName on $difficultyName difficulty';
      case ActivityType.gameDraw:
        return 'Drew $gameName on $difficultyName difficulty${xpEarned > 0 ? ' (+$xpEarned XP)' : ''}';
      default:
        return 'Played $gameName on $difficultyName difficulty';
    }
  }

  Future<void> addLevelUpActivity(int newLevel) async {
    if (state is ProfileLoaded) {
      try {
        final currentProfile = (state as ProfileLoaded).profile;
        final activity = GameActivity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: ActivityType.levelUp,
          title: 'Level Up!',
          description: 'Reached level $newLevel',
          metadata: {'newLevel': newLevel},
          timestamp: DateTime.now(),
        );

        final updatedActivities = [activity, ...currentProfile.activityHistory];
        final limitedActivities = updatedActivities.take(100).toList();

        final updatedProfile = currentProfile.copyWith(
          activityHistory: limitedActivities,
          updatedAt: DateTime.now(),
        );

        final savedProfile = await _profileRepository.updateData(
          updatedProfile,
        );
        emit(ProfileLoaded(savedProfile));
      } catch (e) {
        emit(ProfileError('Failed to add level up activity: $e'));
      }
    }
  }
}
