import '../../../core/repository/cached_repository.dart';
import '../../../core/cache/cache_service.dart';
import '../domain/entities/character.dart';

class CharacterRepository extends CachedListRepository<Character> {
  @override
  String get cacheKey => CacheConfig.charactersKey;

  @override
  Duration get cacheTTL => CacheConfig.charactersCacheTTL;

  @override
  Map<String, dynamic> toJson(Character entity) => entity.toJson();

  @override
  Character fromJson(Map<String, dynamic> json) => Character.fromJson(json);

  @override
  Future<List<Character>> fetchFromRemote() async {
    // Simulate API call - replace with actual Firebase/API calls
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock character data
    return _getDefaultCharacters();
  }

  @override
  Future<void> updateRemoteList(List<Character> data) async {
    // Implement Firebase/API update
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Update Firestore collection
  }

  /// Get character by type
  Future<Character?> getCharacterByType(CharacterType type) async {
    final characters = await getList();
    try {
      return characters.firstWhere((c) => c.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Get unlocked characters
  Future<List<Character>> getUnlockedCharacters() async {
    final characters = await getList();
    return characters.where((c) => c.isUnlocked).toList();
  }

  /// Get locked characters
  Future<List<Character>> getLockedCharacters() async {
    final characters = await getList();
    return characters.where((c) => !c.isUnlocked).toList();
  }

  /// Unlock a character
  Future<Character?> unlockCharacter(CharacterType characterType) async {
    final characters = await getList();
    final characterIndex = characters.indexWhere(
      (c) => c.type == characterType,
    );

    if (characterIndex != -1) {
      final updatedCharacter = characters[characterIndex].copyWith(
        isUnlocked: true,
      );

      final updatedCharacters = List<Character>.from(characters);
      updatedCharacters[characterIndex] = updatedCharacter;

      await updateList(updatedCharacters);
      return updatedCharacter;
    }

    return null;
  }

  /// Level up a character
  Future<Character?> levelUpCharacter(
    CharacterType characterType,
    int xpGained,
  ) async {
    final characters = await getList();
    final characterIndex = characters.indexWhere(
      (c) => c.type == characterType,
    );

    if (characterIndex != -1 && characters[characterIndex].isUnlocked) {
      final character = characters[characterIndex];
      final newExperience = character.experience + xpGained;
      final newLevel = _calculateLevel(newExperience);

      final updatedCharacter = character.copyWith(
        experience: newExperience,
        level: newLevel,
      );

      final updatedCharacters = List<Character>.from(characters);
      updatedCharacters[characterIndex] = updatedCharacter;

      await updateList(updatedCharacters);
      return updatedCharacter;
    }

    return null;
  }

  /// Calculate level from experience
  int _calculateLevel(int experience) {
    // Simple level calculation: 100 XP per level
    return (experience / 100).floor() + 1;
  }

  /// Get default characters
  static List<Character> _getDefaultCharacters() {
    return [
      Character(
        type: CharacterType.nova,
        name: 'Nova',
        description: 'A bright and energetic character with stellar powers',
        imagePath: 'assets/images/characters/nova.png',
        specialty: 'Energy manipulation and speed attacks',
        abilities: {
          'stellar_burst': {'damage': 85, 'cooldown': 3, 'type': 'energy'},
          'light_speed': {'speed_boost': 50, 'duration': 5, 'type': 'movement'},
          'solar_shield': {'defense': 40, 'duration': 8, 'type': 'defense'},
        },
        unlockRequirement: const CharacterUnlockRequirement(
          type: CharacterUnlockType.default_,
          value: 0,
          description: 'Available from start',
        ),
        isUnlocked: true,
        level: 1,
        experience: 0,
        color: ['0xFF1E88E5', '0xFF42A5F5'], // Blue gradient
      ),

      Character(
        type: CharacterType.blitz,
        name: 'Blitz',
        description: 'Lightning-fast warrior with electric powers',
        imagePath: 'assets/images/characters/blitz.png',
        specialty: 'Lightning attacks and high-speed combat',
        abilities: {
          'thunder_strike': {
            'damage': 75,
            'stun_chance': 30,
            'type': 'electric',
          },
          'lightning_dash': {'speed': 80, 'damage': 40, 'type': 'movement'},
          'electric_field': {'area_damage': 60, 'duration': 6, 'type': 'area'},
        },
        unlockRequirement: const CharacterUnlockRequirement(
          type: CharacterUnlockType.level,
          value: 5,
          description: 'Reach player level 5',
        ),
        isUnlocked: false,
        level: 1,
        experience: 0,
        color: ['0xFFFFEB3B', '0xFFFFC107'], // Yellow gradient
      ),

      Character(
        type: CharacterType.zink,
        name: 'Zink',
        description: 'Mysterious robot with advanced technology',
        imagePath: 'assets/images/characters/zink.png',
        specialty: 'Tech abilities and tactical warfare',
        abilities: {
          'laser_beam': {'damage': 90, 'precision': 95, 'type': 'tech'},
          'shield_generator': {
            'shield': 100,
            'duration': 10,
            'type': 'defense',
          },
          'drone_assist': {'support': 70, 'duration': 12, 'type': 'support'},
        },
        unlockRequirement: const CharacterUnlockRequirement(
          type: CharacterUnlockType.wins,
          value: 25,
          description: 'Win 25 games',
        ),
        isUnlocked: false,
        level: 1,
        experience: 0,
        color: ['0xFF9C27B0', '0xFFE91E63'], // Purple-Pink gradient
      ),

      Character(
        type: CharacterType.karma,
        name: 'Karma',
        description: 'Mystical character with balance and harmony powers',
        imagePath: 'assets/images/characters/karma.png',
        specialty: 'Balance manipulation and healing abilities',
        abilities: {
          'balance_strike': {'damage': 70, 'heal': 30, 'type': 'balance'},
          'harmony_aura': {'team_boost': 25, 'duration': 15, 'type': 'support'},
          'karma_reversal': {
            'reflect_damage': 80,
            'duration': 8,
            'type': 'counter',
          },
        },
        unlockRequirement: const CharacterUnlockRequirement(
          type: CharacterUnlockType.xp,
          value: 2500,
          description: 'Earn 2500 total XP',
        ),
        isUnlocked: false,
        level: 1,
        experience: 0,
        color: ['0xFF4CAF50', '0xFF8BC34A'], // Green gradient
      ),

      Character(
        type: CharacterType.rokk,
        name: 'Rokk',
        description: 'Powerful earth elemental with rock-solid defenses',
        imagePath: 'assets/images/characters/rokk.png',
        specialty: 'Earth manipulation and heavy defense',
        abilities: {
          'boulder_smash': {'damage': 100, 'knockback': 80, 'type': 'earth'},
          'stone_wall': {'defense': 150, 'duration': 12, 'type': 'defense'},
          'earthquake': {'area_damage': 85, 'stun': 3, 'type': 'area'},
        },
        unlockRequirement: const CharacterUnlockRequirement(
          type: CharacterUnlockType.badges,
          value: 5,
          description: 'Unlock 5 badges',
        ),
        isUnlocked: false,
        level: 1,
        experience: 0,
        color: ['0xFF795548', '0xFFA1887F'], // Brown gradient
      ),
    ];
  }
}
