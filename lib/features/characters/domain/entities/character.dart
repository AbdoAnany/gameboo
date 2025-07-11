import 'package:equatable/equatable.dart';

enum CharacterType { nova, blitz, zink, karma, rokk }

enum CharacterUnlockType { default_, level, xp, badges, wins }

class Character extends Equatable {
  final CharacterType type;
  final String name;
  final String description;
  final String imagePath;
  final String specialty;
  final Map<String, dynamic> abilities;
  final CharacterUnlockRequirement unlockRequirement;
  final bool isUnlocked;
  final int level;
  final int experience;

  const Character({
    required this.type,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.specialty,
    required this.abilities,
    required this.unlockRequirement,
    this.isUnlocked = false,
    this.level = 1,
    this.experience = 0,
  });

  Character copyWith({
    CharacterType? type,
    String? name,
    String? description,
    String? imagePath,
    String? specialty,
    Map<String, dynamic>? abilities,
    CharacterUnlockRequirement? unlockRequirement,
    bool? isUnlocked,
    int? level,
    int? experience,
  }) {
    return Character(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      specialty: specialty ?? this.specialty,
      abilities: abilities ?? this.abilities,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      level: level ?? this.level,
      experience: experience ?? this.experience,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'specialty': specialty,
      'abilities': abilities,
      'unlockRequirement': unlockRequirement.toJson(),
      'isUnlocked': isUnlocked,
      'level': level,
      'experience': experience,
    };
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      type: CharacterType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CharacterType.nova,
      ),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      specialty: json['specialty'] ?? '',
      abilities: Map<String, dynamic>.from(json['abilities'] ?? {}),
      unlockRequirement: CharacterUnlockRequirement.fromJson(
        json['unlockRequirement'] ?? {},
      ),
      isUnlocked: json['isUnlocked'] ?? false,
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    type,
    name,
    description,
    imagePath,
    specialty,
    abilities,
    unlockRequirement,
    isUnlocked,
    level,
    experience,
  ];
}

class CharacterUnlockRequirement extends Equatable {
  final CharacterUnlockType type;
  final int value;
  final String description;

  const CharacterUnlockRequirement({
    required this.type,
    required this.value,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'value': value, 'description': description};
  }

  factory CharacterUnlockRequirement.fromJson(Map<String, dynamic> json) {
    return CharacterUnlockRequirement(
      type: CharacterUnlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CharacterUnlockType.default_,
      ),
      value: json['value'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [type, value, description];
}

class CharacterRepository {
  static const List<Character> defaultCharacters = [
    Character(
      type: CharacterType.nova,
      name: 'Nova',
      description: 'A futuristic pilot with exceptional focus and precision',
      imagePath: 'assets/images/characters/nova.png',
      specialty: 'Drone flying & high focus games',
      abilities: {'focus_boost': 1.2, 'drone_control': 1.5, 'precision': 1.3},
      unlockRequirement: CharacterUnlockRequirement(
        type: CharacterUnlockType.default_,
        value: 0,
        description: 'Default starter character',
      ),
      isUnlocked: true,
    ),
    Character(
      type: CharacterType.blitz,
      name: 'Blitz',
      description: 'A cool racer with lightning-fast reflexes',
      imagePath: 'assets/images/characters/blitz.png',
      specialty: 'Racing & reflex-based games',
      abilities: {'speed_boost': 1.3, 'reflex_time': 1.4, 'racing_bonus': 1.5},
      unlockRequirement: CharacterUnlockRequirement(
        type: CharacterUnlockType.level,
        value: 5,
        description: 'Reach Level 5',
      ),
    ),
    Character(
      type: CharacterType.zink,
      name: 'Zink',
      description: 'A brilliant robot with advanced problem-solving algorithms',
      imagePath: 'assets/images/characters/zink.png',
      specialty: 'Puzzle-solving master',
      abilities: {
        'logic_boost': 1.4,
        'pattern_recognition': 1.5,
        'puzzle_hint': 1.2,
      },
      unlockRequirement: CharacterUnlockRequirement(
        type: CharacterUnlockType.xp,
        value: 500,
        description: 'Earn 500 XP',
      ),
    ),
    Character(
      type: CharacterType.karma,
      name: 'Karma',
      description: 'A mystical card master with magical powers',
      imagePath: 'assets/images/characters/karma.png',
      specialty: 'Card shooting & magical games',
      abilities: {'card_power': 1.5, 'magic_boost': 1.3, 'accuracy': 1.4},
      unlockRequirement: CharacterUnlockRequirement(
        type: CharacterUnlockType.badges,
        value: 5,
        description: 'Collect 5 badges',
      ),
    ),
    Character(
      type: CharacterType.rokk,
      name: 'Rokk',
      description: 'A powerful destroyer with incredible strength',
      imagePath: 'assets/images/characters/rokk.png',
      specialty: 'Ball games & destruction',
      abilities: {
        'strength_boost': 1.5,
        'destruction_power': 1.6,
        'ball_control': 1.3,
      },
      unlockRequirement: CharacterUnlockRequirement(
        type: CharacterUnlockType.wins,
        value: 10,
        description: 'Win 10 games',
      ),
    ),
  ];

  static Character getCharacterByType(CharacterType type) {
    return defaultCharacters.firstWhere(
      (character) => character.type == type,
      orElse: () => defaultCharacters.first,
    );
  }

  static List<Character> getAllCharacters() {
    return List.from(defaultCharacters);
  }
}
