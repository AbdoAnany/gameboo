import 'package:equatable/equatable.dart';

enum ActivityType {
  gameWin,
  gameLoss,
  gameDraw,
  levelUp,
  badgeEarned,
  xpGained,
  characterUnlocked,
  shopPurchase,
  challengeCompleted,
}

enum GameType {
  rockPaperScissors,
  ticTacToe,
  memoryCards,
  puzzleSolving,
  ballBlaster,
  cardShooter,
  racingRush,
  droneFlight,
  puzzleMania,
}

class GameActivity extends Equatable {
  final String id;
  final ActivityType type;
  final GameType? gameType;
  final String title;
  final String description;
  final int xpEarned;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const GameActivity({
    required this.id,
    required this.type,
    this.gameType,
    required this.title,
    required this.description,
    this.xpEarned = 0,
    this.metadata = const {},
    required this.timestamp,
  });

  GameActivity copyWith({
    String? id,
    ActivityType? type,
    GameType? gameType,
    String? title,
    String? description,
    int? xpEarned,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return GameActivity(
      id: id ?? this.id,
      type: type ?? this.type,
      gameType: gameType ?? this.gameType,
      title: title ?? this.title,
      description: description ?? this.description,
      xpEarned: xpEarned ?? this.xpEarned,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'gameType': gameType?.name,
      'title': title,
      'description': description,
      'xpEarned': xpEarned,
      'metadata': metadata,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory GameActivity.fromJson(Map<String, dynamic> json) {
    return GameActivity(
      id: json['id'] ?? '',
      type: ActivityType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ActivityType.xpGained,
      ),
      gameType: json['gameType'] != null
          ? GameType.values.firstWhere(
              (e) => e.name == json['gameType'],
              orElse: () => GameType.ticTacToe,
            )
          : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      xpEarned: json['xpEarned'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    gameType,
    title,
    description,
    xpEarned,
    metadata,
    timestamp,
  ];
}

// Helper class to generate activity descriptions
class ActivityHelper {
  static String getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.gameWin:
        return '🏆';
      case ActivityType.gameLoss:
        return '💔';
      case ActivityType.gameDraw:
        return '🤝';
      case ActivityType.levelUp:
        return '⬆️';
      case ActivityType.badgeEarned:
        return '🏅';
      case ActivityType.xpGained:
        return '✨';
      case ActivityType.characterUnlocked:
        return '🔓';
      case ActivityType.shopPurchase:
        return '🛒';
      case ActivityType.challengeCompleted:
        return '✅';
    }
  }

  static String getGameDisplayName(GameType gameType) {
    switch (gameType) {
      case GameType.rockPaperScissors:
        return 'Rock Paper Scissors';
      case GameType.ticTacToe:
        return 'Tic Tac Toe';
      case GameType.memoryCards:
        return 'Memory Cards';
      case GameType.puzzleSolving:
        return 'Puzzle Solving';
      case GameType.ballBlaster:
        return 'Ball Blaster';
      case GameType.cardShooter:
        return 'Card Shooter';
      case GameType.racingRush:
        return 'Racing Rush';
      case GameType.droneFlight:
        return 'Drone Flight';
      case GameType.puzzleMania:
        return 'Puzzle Mania';
    }
  }

  static String getDifficultyDisplayName(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'medium':
        return 'Medium';
      case 'hard':
        return 'Hard';
      case 'expert':
        return 'Expert';
      default:
        return difficulty;
    }
  }
}
