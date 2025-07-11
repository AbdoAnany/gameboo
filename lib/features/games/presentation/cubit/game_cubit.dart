import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/game.dart';

// Game States
abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final List<GameMetadata> games;
  final List<GameSession> sessions;

  const GameLoaded(this.games, this.sessions);

  @override
  List<Object?> get props => [games, sessions];
}

class GamePlaying extends GameState {
  final GameSession currentSession;

  const GamePlaying(this.currentSession);

  @override
  List<Object?> get props => [currentSession];
}

class GameCompleted extends GameState {
  final GameSession completedSession;

  const GameCompleted(this.completedSession);

  @override
  List<Object?> get props => [completedSession];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object?> get props => [message];
}

// Game Cubit
class GameCubit extends Cubit<GameState> {
  List<GameSession> _sessions = [];

  GameCubit() : super(GameInitial()) {
    _loadGames();
  }

  void _loadGames() {
    emit(GameLoading());

    try {
      final games = GameRepository.getAllGames();
      emit(GameLoaded(games, _sessions));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }

  void startGame(GameType gameType, GameDifficulty difficulty) {
    final session = GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      gameType: gameType,
      difficulty: difficulty,
      status: GameStatus.playing,
      startedAt: DateTime.now(),
    );

    _sessions.add(session);
    emit(GamePlaying(session));
  }

  void updateGameSession(GameSession session) {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;

      if (session.status == GameStatus.completed ||
          session.status == GameStatus.failed) {
        emit(GameCompleted(session));
      } else {
        emit(GamePlaying(session));
      }
    }
  }

  void pauseGame(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final pausedSession = session.copyWith(status: GameStatus.paused);
    updateGameSession(pausedSession);
  }

  void resumeGame(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final resumedSession = session.copyWith(status: GameStatus.playing);
    updateGameSession(resumedSession);
  }

  void completeGame(String sessionId, int score, int xpEarned) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final completedSession = session.copyWith(
      status: GameStatus.completed,
      score: score,
      xpEarned: xpEarned,
      completedAt: DateTime.now(),
    );
    updateGameSession(completedSession);
  }

  void failGame(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId);
    final failedSession = session.copyWith(
      status: GameStatus.failed,
      completedAt: DateTime.now(),
    );
    updateGameSession(failedSession);
  }

  List<GameSession> getSessionsByGame(GameType gameType) {
    return _sessions.where((session) => session.gameType == gameType).toList();
  }

  int getHighScore(GameType gameType, GameDifficulty difficulty) {
    final gameSessions = _sessions
        .where(
          (session) =>
              session.gameType == gameType &&
              session.difficulty == difficulty &&
              session.status == GameStatus.completed,
        )
        .toList();

    if (gameSessions.isEmpty) return 0;
    return gameSessions.map((s) => s.score).reduce((a, b) => a > b ? a : b);
  }

  List<GameMetadata> getUnlockedGames(int userLevel) {
    if (state is GameLoaded) {
      final currentState = state as GameLoaded;
      return currentState.games
          .where((game) => userLevel >= game.unlockLevel)
          .toList();
    }
    return [];
  }
}
