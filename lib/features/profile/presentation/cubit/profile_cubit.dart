import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';
import '../../../characters/domain/entities/character.dart';

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
  ProfileCubit() : super(ProfileInitial()) {
    _loadProfile();
  }

  void _loadProfile() {
    emit(ProfileLoading());

    // For now, create a default profile
    // In a real app, this would load from Firebase/local storage
    final profile = UserProfile(
      id: 'default_user',
      username: 'GameBoo Player',
      email: 'player@gameboo.com',
      xp: 0,
      level: 1,
      selectedCharacter: CharacterType.nova,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      coins: 1000, // Starting coins
      gems: 50, // Starting gems
      ownedShopItems: [], // No items owned initially
    );

    emit(ProfileLoaded(profile));
  }

  void updateProfile(UserProfile profile) {
    emit(ProfileLoaded(profile));
  }

  void addXP(int xp) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      int totalXP = currentProfile.xp + xp;
      int newLevel = _calculateLevelFromXP(totalXP);
      // Clamp XP to max for new level if needed
      final updatedProfile = currentProfile.copyWith(
        xp: totalXP,
        level: newLevel,
        updatedAt: DateTime.now(),
      );
      emit(ProfileLoaded(updatedProfile));
    }
  }

  void selectCharacter(CharacterType character) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final updatedProfile = currentProfile.copyWith(
        selectedCharacter: character,
        updatedAt: DateTime.now(),
      );

      emit(ProfileLoaded(updatedProfile));
    }
  }

  void incrementGameWin(String gameType) {
    if (state is ProfileLoaded) {
      final currentProfile = (state as ProfileLoaded).profile;
      final newGameStats = Map<String, int>.from(currentProfile.gameStats);
      newGameStats[gameType] = (newGameStats[gameType] ?? 0) + 1;

      final updatedProfile = currentProfile.copyWith(
        gameStats: newGameStats,
        updatedAt: DateTime.now(),
      );

      emit(ProfileLoaded(updatedProfile));
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

  // Calculate level from total XP
  int _calculateLevelFromXP(int totalXP) {
    if (totalXP < 1000) return 1;

    int level = 1;
    int xpForLevel = 1000;

    while (totalXP >= xpForLevel) {
      level++;
      xpForLevel = _calculateLevelXP(level);
    }

    return level - 1; // Return the completed level
  }
}
