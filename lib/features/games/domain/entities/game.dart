import 'package:equatable/equatable.dart';

enum GameType {
  rockPaperScissors,
  ticTacToe,
  memoryCards,
  shootingGame,
  carRacing,
  droneFlight,
  mcqQuiz,
  ballBlaster,
  puzzleMania,
  towerBuilding,
  droneShooter,
}

enum GameDifficulty { easy, medium, hard, expert }

enum GameStatus { notStarted, playing, paused, completed, failed }

class GameMetadata extends Equatable {
  final GameType type;
  final String name;
  final String description;
  final String thumbnailPath;
  final String iconPath;
  final List<GameDifficulty> availableDifficulties;
  final Map<String, dynamic> gameSettings;
  final bool isUnlocked;
  final int unlockLevel;

  const GameMetadata({
    required this.type,
    required this.name,
    required this.description,
    required this.thumbnailPath,
    required this.iconPath,
    required this.availableDifficulties,
    required this.gameSettings,
    this.isUnlocked = true,
    this.unlockLevel = 1,
  });

  GameMetadata copyWith({
    GameType? type,
    String? name,
    String? description,
    String? thumbnailPath,
    String? iconPath,
    List<GameDifficulty>? availableDifficulties,
    Map<String, dynamic>? gameSettings,
    bool? isUnlocked,
    int? unlockLevel,
  }) {
    return GameMetadata(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      iconPath: iconPath ?? this.iconPath,
      availableDifficulties:
          availableDifficulties ?? this.availableDifficulties,
      gameSettings: gameSettings ?? this.gameSettings,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockLevel: unlockLevel ?? this.unlockLevel,
    );
  }

  @override
  List<Object?> get props => [
    type,
    name,
    description,
    thumbnailPath,
    iconPath,
    availableDifficulties,
    gameSettings,
    isUnlocked,
    unlockLevel,
  ];
}

class GameSession extends Equatable {
  final String id;
  final GameType gameType;
  final GameDifficulty difficulty;
  final GameStatus status;
  final int score;
  final int highScore;
  final int xpEarned;
  final Duration playTime;
  final Map<String, dynamic> gameData;
  final DateTime startedAt;
  final DateTime? completedAt;

  const GameSession({
    required this.id,
    required this.gameType,
    required this.difficulty,
    required this.status,
    this.score = 0,
    this.highScore = 0,
    this.xpEarned = 0,
    this.playTime = Duration.zero,
    this.gameData = const {},
    required this.startedAt,
    this.completedAt,
  });

  GameSession copyWith({
    String? id,
    GameType? gameType,
    GameDifficulty? difficulty,
    GameStatus? status,
    int? score,
    int? highScore,
    int? xpEarned,
    Duration? playTime,
    Map<String, dynamic>? gameData,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return GameSession(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      xpEarned: xpEarned ?? this.xpEarned,
      playTime: playTime ?? this.playTime,
      gameData: gameData ?? this.gameData,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'score': score,
      'highScore': highScore,
      'xpEarned': xpEarned,
      'playTime': playTime.inMilliseconds,
      'gameData': gameData,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] ?? '',
      gameType: GameType.values.firstWhere(
        (e) => e.name == json['gameType'],
        orElse: () => GameType.rockPaperScissors,
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => GameDifficulty.easy,
      ),
      status: GameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameStatus.notStarted,
      ),
      score: json['score'] ?? 0,
      highScore: json['highScore'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      playTime: Duration(milliseconds: json['playTime'] ?? 0),
      gameData: Map<String, dynamic>.from(json['gameData'] ?? {}),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        json['startedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    gameType,
    difficulty,
    status,
    score,
    highScore,
    xpEarned,
    playTime,
    gameData,
    startedAt,
    completedAt,
  ];
}

class LeaderboardEntry extends Equatable {
  final String id;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String? country;
  final GameType gameType;
  final GameDifficulty? difficulty;
  final int score;
  final int rank;
  final DateTime achievedAt;

  const LeaderboardEntry({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.country,
    required this.gameType,
    this.difficulty,
    required this.score,
    required this.rank,
    required this.achievedAt,
  });

  LeaderboardEntry copyWith({
    String? id,
    String? userId,
    String? username,
    String? avatarUrl,
    String? country,
    GameType? gameType,
    GameDifficulty? difficulty,
    int? score,
    int? rank,
    DateTime? achievedAt,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      country: country ?? this.country,
      gameType: gameType ?? this.gameType,
      difficulty: difficulty ?? this.difficulty,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'country': country,
      'gameType': gameType.name,
      'difficulty': difficulty?.name,
      'score': score,
      'rank': rank,
      'achievedAt': achievedAt.millisecondsSinceEpoch,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      country: json['country'],
      gameType: GameType.values.firstWhere(
        (e) => e.name == json['gameType'],
        orElse: () => GameType.rockPaperScissors,
      ),
      difficulty: json['difficulty'] != null
          ? GameDifficulty.values.firstWhere(
              (e) => e.name == json['difficulty'],
              orElse: () => GameDifficulty.easy,
            )
          : null,
      score: json['score'] ?? 0,
      rank: json['rank'] ?? 0,
      achievedAt: DateTime.fromMillisecondsSinceEpoch(
        json['achievedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    avatarUrl,
    country,
    gameType,
    difficulty,
    score,
    rank,
    achievedAt,
  ];
}

class GameRepository {
  static const List<GameMetadata> games = [
    GameMetadata(
      type: GameType.rockPaperScissors,
      name: 'Rock Paper Scissors',
      description: 'Classic game against AI with multiple difficulty levels',
      thumbnailPath: 'assets/images/games/rock_paper_scissors_thumb.png',
      iconPath: 'assets/images/games/rock_paper_scissors_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'rounds': 5, 'timeLimit': 10, 'aiStrategy': 'adaptive'},
    ),
    GameMetadata(
      type: GameType.ticTacToe,
      name: 'Tic Tac Toe',
      description: 'Strategic 3x3 grid game with smart AI opponent',
      thumbnailPath: 'assets/images/games/tic_tac_toe_thumb.png',
      iconPath: 'assets/images/games/tic_tac_toe_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'boardSize': 3, 'aiDepth': 5, 'firstPlayer': 'player'},
    ),
    GameMetadata(
      type: GameType.memoryCards,
      name: 'Memory Cards',
      description: 'Test your memory with matching card pairs',
      thumbnailPath: 'assets/images/games/memory_cards_thumb.png',
      iconPath: 'assets/images/games/memory_cards_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'gridSize': 4, 'timeLimit': 120, 'maxMistakes': 5},
    ),
    GameMetadata(
      type: GameType.shootingGame,
      name: 'Shooting Game',
      description: 'Fast-paced shooting with moving targets',
      thumbnailPath: 'assets/images/games/shooting_game_thumb.png',
      iconPath: 'assets/images/games/shooting_game_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'ammo': 30, 'timeLimit': 60, 'targetSpeed': 2.0},
      unlockLevel: 2,
    ),
    // GameMetadata(
    //   type: GameType.carRacing,
    //   name: 'Car Racing',
    //   description: '2D racing with obstacles and time challenges',
    //   thumbnailPath: 'assets/images/games/car_racing_thumb.png',
    //   iconPath: 'assets/images/games/car_racing_icon.png',
    //   availableDifficulties: [
    //     GameDifficulty.easy,
    //     GameDifficulty.medium,
    //     GameDifficulty.hard,
    //     GameDifficulty.expert,
    //   ],
    //   gameSettings: {'laps': 3, 'maxSpeed': 200.0, 'obstacleCount': 15},
    //   unlockLevel: 3,
    // ),
    GameMetadata(
      type: GameType.droneFlight,
      name: 'Drone Flight',
      description: 'Navigate drone through obstacles and checkpoints',
      thumbnailPath: 'assets/images/games/drone_flight_thumb.png',
      iconPath: 'assets/images/games/drone_flight_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'checkpoints': 5, 'maxSpeed': 150.0, 'obstacleCount': 20},
      unlockLevel: 4,
    ),
    GameMetadata(
      type: GameType.mcqQuiz,
      name: 'MCQ Quiz',
      description: 'Multiple choice questions across various topics',
      thumbnailPath: 'assets/images/games/mcq_quiz_thumb.png',
      iconPath: 'assets/images/games/mcq_quiz_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {
        'questionsCount': 10,
        'timePerQuestion': 30,
        'categories': ['general', 'science', 'history'],
      },
      unlockLevel: 5,
    ),
    GameMetadata(
      type: GameType.ballBlaster,
      name: 'Ball Blaster',
      description: 'Break bricks and targets with bouncing balls',
      thumbnailPath: 'assets/images/games/ball_blaster_thumb.png',
      iconPath: 'assets/images/games/ball_blaster_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {'maxBalls': 5, 'bricksPerLevel': 30, 'ballSpeed': 300.0},
      unlockLevel: 6,
    ),
    // GameMetadata(
    //   type: GameType.puzzleMania,
    //   name: 'Puzzle Mania',
    //   description: 'Classic logic puzzles including match-3 and tile swap',
    //   thumbnailPath: 'assets/images/games/puzzle_mania_thumb.png',
    //   iconPath: 'assets/images/games/puzzle_mania_icon.png',
    //   availableDifficulties: [
    //     GameDifficulty.easy,
    //     GameDifficulty.medium,
    //     GameDifficulty.hard,
    //     GameDifficulty.expert,
    //   ],
    //   gameSettings: {'gridSize': 8, 'targetScore': 150, 'timeLimit': 180},
    //   unlockLevel: 7,
    // ),
    GameMetadata(
      type: GameType.droneShooter,
      name: 'Drone Shooter',
      description: 'Side-scrolling shooter game with upgrades and power-ups',
      thumbnailPath: 'assets/images/games/drone_shooter_thumb.png',
      iconPath: 'assets/images/games/drone_shooter_icon.png',
      availableDifficulties: [
        GameDifficulty.easy,
        GameDifficulty.medium,
        GameDifficulty.hard,
        GameDifficulty.expert,
      ],
      gameSettings: {
        'enemySpawnRate': 2.0,
        'droneSpeed': 200,
        'maxHealth': 100,
      },
      unlockLevel: 8,
    ),
  ];

  static GameMetadata getGameByType(GameType type) {
    return games.firstWhere(
      (game) => game.type == type,
      orElse: () => games.first,
    );
  }

  static List<GameMetadata> getUnlockedGames(int userLevel) {
    return games.where((game) => userLevel >= game.unlockLevel).toList();
  }

  static List<GameMetadata> getAllGames() {
    return List.from(games);
  }
}
