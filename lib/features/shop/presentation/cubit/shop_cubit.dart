import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../domain/entities/shop_item.dart';
import '../../../characters/domain/entities/character.dart';

// Shop States
abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopLoaded extends ShopState {
  final List<ShopItem> items;
  final PlayerWallet wallet;

  const ShopLoaded({required this.items, required this.wallet});

  @override
  List<Object?> get props => [items, wallet];
}

class ShopError extends ShopState {
  final String message;

  const ShopError(this.message);

  @override
  List<Object?> get props => [message];
}

class ShopPurchaseSuccess extends ShopState {
  final ShopItem item;
  final PlayerWallet updatedWallet;

  const ShopPurchaseSuccess({required this.item, required this.updatedWallet});

  @override
  List<Object?> get props => [item, updatedWallet];
}

// Shop Cubit
class ShopCubit extends Cubit<ShopState> {
  ShopCubit() : super(ShopInitial());

  void loadShop({PlayerWallet? wallet}) {
    emit(ShopLoading());

    // Sample shop items - in a real app, this would come from Firebase/API
    final shopItems = [
      // Tickets
      ShopItem(
        id: 'ticket_1',
        name: 'Golden Ticket',
        description: 'A special ticket that gives you bonus XP for 1 hour',
        imagePath: 'assets/images/tickets/golden_ticket.png',
        type: ShopItemType.ticket,
        currencyType: CurrencyType.coins,
        price: 5000,
        properties: {
          'duration': 3600, // 1 hour in seconds
          'xpMultiplier': 2.0,
        },
      ),
      ShopItem(
        id: 'ticket_2',
        name: 'Diamond Ticket',
        description: 'Premium ticket that doubles your score for 30 minutes',
        imagePath: 'assets/images/tickets/diamond_ticket.png',
        type: ShopItemType.ticket,
        currencyType: CurrencyType.gems,
        price: 5000,
        properties: {
          'duration': 1800, // 30 minutes
          'scoreMultiplier': 2.0,
        },
      ),

      // Monsters
      ShopItem(
        id: 'monster_1',
        name: 'Fire Dragon',
        description: 'A powerful fire dragon companion that boosts damage',
        imagePath: 'assets/images/monsters/fire_dragon.png',
        type: ShopItemType.monster,
        currencyType: CurrencyType.coins,
        price: 20000,
        properties: {'damageBoost': 25, 'element': 'fire'},
      ),
      ShopItem(
        id: 'monster_2',
        name: 'Ice Phoenix',
        description: 'Majestic ice phoenix that freezes enemies',
        imagePath: 'assets/images/monsters/ice_phoenix.png',
        type: ShopItemType.monster,
        currencyType: CurrencyType.gems,
        price: 10000,
        properties: {'freezeChance': 30, 'element': 'ice'},
      ),
      ShopItem(
        id: 'monster_3',
        name: 'Shadow Wolf',
        description: 'Stealthy wolf that increases critical hit chance',
        imagePath: 'assets/images/monsters/shadow_wolf.png',
        type: ShopItemType.monster,
        currencyType: CurrencyType.coins,
        price: 1500,
        properties: {'criticalChance': 20, 'element': 'shadow'},
      ),

      // Characters
      ShopItem(
        id: 'char_blitz',
        name: 'Blitz Character',
        description: 'Unlock the lightning-fast Blitz character',
        imagePath: 'assets/images/characters/blitz.png',
        type: ShopItemType.character,
        currencyType: CurrencyType.xp,
        price: 50000,
        characterType: CharacterType.blitz,
        properties: {'speed': 'high', 'special': 'lightning_dash'},
      ),
      ShopItem(
        id: 'char_zink',
        name: 'Zink Character',
        description: 'Unlock the tech-savvy Zink character',
        imagePath: 'assets/images/characters/zink.png',
        type: ShopItemType.character,
        currencyType: CurrencyType.gems,
        price: 1500,
        characterType: CharacterType.zink,
        properties: {'tech': 'high', 'special': 'gadget_boost'},
      ),

      // Power-ups
      ShopItem(
        id: 'powerup_1',
        name: 'Shield Boost',
        description: 'Temporary shield that protects from damage',
        imagePath: 'assets/images/powerups/shield.png',
        type: ShopItemType.powerup,
        currencyType: CurrencyType.coins,
        price: 1000,
        properties: {'duration': 30, 'protection': 100},
      ),
      ShopItem(
        id: 'powerup_2',
        name: 'Speed Boost',
        description: 'Increases movement speed for a short time',
        imagePath: 'assets/images/powerups/speed.png',
        type: ShopItemType.powerup,
        currencyType: CurrencyType.coins,
        price: 7500,
        properties: {'duration': 20, 'speedMultiplier': 1.5},
      ),
    ];

    // Sample wallet - in a real app, this would come from user data
    final defaultWallet = PlayerWallet(
      coins: 3000,
      gems: 250,
      tickets: 5,
      ownedItems: ['ticket_1'], // User already owns golden ticket
    );

    final finalWallet = wallet ?? defaultWallet;

    emit(ShopLoaded(items: shopItems, wallet: finalWallet));
  }

  void purchaseItem(ShopItem item, int userXP,context) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;
      final wallet = currentState.wallet;

      // Check if user can afford the item
      bool canAfford = false;
      switch (item.currencyType) {
        case CurrencyType.coins:
          canAfford = wallet.coins >= item.price;
          break;
        case CurrencyType.gems:
          canAfford = wallet.gems >= item.price;
          break;
        case CurrencyType.xp:
          canAfford = userXP >= item.price;
          break;
      }

      if (!canAfford) {
        emit(ShopError('Insufficient ${item.currencyType.name}!'));
        return;
      }

      if (wallet.ownedItems.contains(item.id)) {
        emit(ShopError('You already own this item!'));
        return;
      }

      // Deduct currency and add item
      PlayerWallet updatedWallet;
      switch (item.currencyType) {
        case CurrencyType.coins:
          updatedWallet = wallet.copyWith(
            coins: wallet.coins - item.price,
            ownedItems: [...wallet.ownedItems, item.id],
          );
          break;
        case CurrencyType.gems:
          updatedWallet = wallet.copyWith(
            gems: wallet.gems - item.price,
            ownedItems: [...wallet.ownedItems, item.id],
          );
          break;
        case CurrencyType.xp:
          // XP is handled in ProfileCubit, just add the item
          updatedWallet = wallet.copyWith(
            ownedItems: [...wallet.ownedItems, item.id],
          );
          break;
      }

      // Update shop items to mark as owned
      final updatedItems = currentState.items.map((shopItem) {
        if (shopItem.id == item.id) {
          return shopItem.copyWith(isOwned: true);
        }
        return shopItem;
      }).toList();
      ProfileCubit.singleton().purchaseShopItem(item.id);

      emit(ShopPurchaseSuccess(item: item, updatedWallet: updatedWallet));

      // Reload shop with updated data
      Future.delayed(const Duration(seconds: 1), () {
        emit(ShopLoaded(items: updatedItems, wallet: updatedWallet));
      });
    }
  }

  void addCurrency(CurrencyType type, int amount) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;
      final wallet = currentState.wallet;

      PlayerWallet updatedWallet;
      switch (type) {
        case CurrencyType.coins:
          updatedWallet = wallet.copyWith(coins: wallet.coins + amount);
          break;
        case CurrencyType.gems:
          updatedWallet = wallet.copyWith(gems: wallet.gems + amount);
          break;
        case CurrencyType.xp:
          // XP is handled in ProfileCubit
          return;
      }

      emit(ShopLoaded(items: currentState.items, wallet: updatedWallet));
    }
  }

  void filterByType(ShopItemType? type) {
    if (state is ShopLoaded) {
      // This would filter the display, but for now we'll just reload
      loadShop();
    }
  }
}
