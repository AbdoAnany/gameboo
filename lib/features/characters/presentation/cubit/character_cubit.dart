import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/character.dart';

// Character States
abstract class CharacterState extends Equatable {
  const CharacterState();

  @override
  List<Object?> get props => [];
}

class CharacterInitial extends CharacterState {}

class CharacterLoading extends CharacterState {}

class CharacterLoaded extends CharacterState {
  final List<Character> characters;
  final Character selectedCharacter;

  const CharacterLoaded(this.characters, this.selectedCharacter);

  @override
  List<Object?> get props => [characters, selectedCharacter];
}

class CharacterError extends CharacterState {
  final String message;

  const CharacterError(this.message);

  @override
  List<Object?> get props => [message];
}

// Character Cubit
class CharacterCubit extends Cubit<CharacterState> {
  CharacterCubit() : super(CharacterInitial()) {
    _loadCharacters();
  }

  void _loadCharacters() {
    emit(CharacterLoading());

    try {
      // Load characters from repository
      final characters = CharacterRepository.getAllCharacters();
      final selectedCharacter = characters.first; // Default to Nova

      emit(CharacterLoaded(characters, selectedCharacter));
    } catch (e) {
      emit(CharacterError(e.toString()));
    }
  }

  void selectCharacter(CharacterType characterType) {
    if (state is CharacterLoaded) {
      final currentState = state as CharacterLoaded;
      final character = currentState.characters.firstWhere(
        (c) => c.type == characterType,
        orElse: () => currentState.characters.first,
      );

      emit(CharacterLoaded(currentState.characters, character));
    }
  }

  void unlockCharacter(CharacterType characterType) {
    if (state is CharacterLoaded) {
      final currentState = state as CharacterLoaded;
      final updatedCharacters = currentState.characters.map((character) {
        if (character.type == characterType) {
          return character.copyWith(isUnlocked: true);
        }
        return character;
      }).toList();

      emit(CharacterLoaded(updatedCharacters, currentState.selectedCharacter));
    }
  }

  void levelUpCharacter(CharacterType characterType, int xp) {
    if (state is CharacterLoaded) {
      final currentState = state as CharacterLoaded;
      final updatedCharacters = currentState.characters.map((character) {
        if (character.type == characterType) {
          final newXP = character.experience + xp;
          final newLevel = (newXP / 100).floor() + 1;
          return character.copyWith(experience: newXP, level: newLevel);
        }
        return character;
      }).toList();

      final selectedCharacter =
          currentState.selectedCharacter.type == characterType
          ? updatedCharacters.firstWhere((c) => c.type == characterType)
          : currentState.selectedCharacter;

      emit(CharacterLoaded(updatedCharacters, selectedCharacter));
    }
  }

  bool isCharacterUnlocked(
    CharacterType characterType,
    int userLevel,
    int userXP,
    int userBadges,
    int userWins,
  ) {
    final character = CharacterRepository.getCharacterByType(characterType);

    switch (character.unlockRequirement.type) {
      case CharacterUnlockType.default_:
        return true;
      case CharacterUnlockType.level:
        return userLevel >= character.unlockRequirement.value;
      case CharacterUnlockType.xp:
        return userXP >= character.unlockRequirement.value;
      case CharacterUnlockType.badges:
        return userBadges >= character.unlockRequirement.value;
      case CharacterUnlockType.wins:
        return userWins >= character.unlockRequirement.value;
    }
  }
}
