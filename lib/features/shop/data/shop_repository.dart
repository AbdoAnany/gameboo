import '../../../core/repository/cached_repository.dart';
import '../../../core/cache/cache_service.dart';
import '../domain/entities/shop_item.dart';
import '../../characters/domain/entities/character.dart';

class ShopRepository extends CachedListRepository<ShopItem> {
  @override
  String get cacheKey => CacheConfig.shopKey;

  @override
  Duration get cacheTTL => CacheConfig.shopCacheTTL;

  @override
  Map<String, dynamic> toJson(ShopItem entity) => entity.toJson();

  @override
  ShopItem fromJson(Map<String, dynamic> json) => ShopItem.fromJson(json);

  @override
  Future<List<ShopItem>> fetchFromRemote() async {
    // Simulate API call - replace with actual Firebase/API calls
    await Future.delayed(const Duration(milliseconds: 600));

    // Return mock shop items
    return [
      const ShopItem(
        id: 'power_boost',
        name: 'Power Boost',
        description: 'Double your XP for 1 hour',
        imagePath: 'assets/images/shop/power_boost.png',
        type: ShopItemType.powerup,
        currencyType: CurrencyType.coins,
        price: 100,
        properties: {'duration': 3600, 'multiplier': 2.0},
      ),
      const ShopItem(
        id: 'extra_life',
        name: 'Extra Life',
        description: 'Get an extra chance in challenging games',
        imagePath: 'assets/images/shop/extra_life.png',
        type: ShopItemType.powerup,
        currencyType: CurrencyType.coins,
        price: 50,
        properties: {'uses': 1},
      ),
      const ShopItem(
        id: 'gem_bundle_small',
        name: 'Small Gem Bundle',
        description: '50 gems for premium purchases',
        imagePath: 'assets/images/shop/gem_bundle.png',
        type: ShopItemType.ticket,
        currencyType: CurrencyType.coins,
        price: 500,
        properties: {'gems': 50},
      ),
      const ShopItem(
        id: 'nova_golden_skin',
        name: 'Nova Golden Skin',
        description: 'Exclusive golden skin for Nova character',
        imagePath: 'assets/images/shop/nova_golden.png',
        type: ShopItemType.skin,
        currencyType: CurrencyType.gems,
        price: 25,
        characterType: CharacterType.nova,
        properties: {'rarity': 'legendary'},
      ),
      const ShopItem(
        id: 'blitz_speedster_skin',
        name: 'Blitz Speedster Skin',
        description: 'Lightning-fast skin for Blitz',
        imagePath: 'assets/images/shop/blitz_speedster.png',
        type: ShopItemType.skin,
        currencyType: CurrencyType.gems,
        price: 20,
        characterType: CharacterType.blitz,
        properties: {'rarity': 'epic'},
      ),
      ShopItem(
        id: 'weekend_special',
        name: 'Weekend XP Boost',
        description: 'Triple XP for the weekend!',
        imagePath: 'assets/images/shop/weekend_boost.png',
        type: ShopItemType.powerup,
        currencyType: CurrencyType.gems,
        price: 15,
        isLimited: true,
        expiryDate: DateTime.now().add(const Duration(days: 2)),
        properties: {'duration': 172800, 'multiplier': 3.0}, // 48 hours
      ),
    ];
  }

  @override
  Future<void> updateRemoteList(List<ShopItem> data) async {
    // Implement Firebase/API update for shop items
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: Update Firestore collection
  }

  /// Purchase an item
  Future<ShopItem> purchaseItem(String itemId, PlayerWallet wallet) async {
    final items = await getList();
    final item = items.firstWhere((i) => i.id == itemId);

    // Check if user can afford the item
    if (!wallet.canAfford(item)) {
      throw InsufficientFundsException(
        'Not enough ${item.currencyType.name} to purchase ${item.name}',
      );
    }

    // Mark item as owned
    final updatedItem = item.copyWith(isOwned: true);
    final updatedItems = items
        .map((i) => i.id == itemId ? updatedItem : i)
        .toList();

    // Update cache with optimistic update
    await updateList(updatedItems);

    return updatedItem;
  }

  /// Get items by type
  Future<List<ShopItem>> getItemsByType(ShopItemType type) async {
    final items = await getList();
    return items.where((item) => item.type == type).toList();
  }

  /// Get items for a specific character
  Future<List<ShopItem>> getItemsForCharacter(
    CharacterType characterType,
  ) async {
    final items = await getList();
    return items.where((item) => item.characterType == characterType).toList();
  }

  /// Get limited time offers
  Future<List<ShopItem>> getLimitedOffers() async {
    final items = await getList();
    final now = DateTime.now();
    return items
        .where(
          (item) =>
              item.isLimited &&
              (item.expiryDate == null || item.expiryDate!.isAfter(now)),
        )
        .toList();
  }

  /// Get affordable items for user's wallet
  Future<List<ShopItem>> getAffordableItems(PlayerWallet wallet) async {
    final items = await getList();
    return items.where((item) => wallet.canAfford(item)).toList();
  }
}

/// Player wallet for shop transactions
class PlayerWallet {
  final int coins;
  final int gems;
  final int xp;

  const PlayerWallet({
    required this.coins,
    required this.gems,
    required this.xp,
  });

  /// Check if player can afford an item
  bool canAfford(ShopItem item) {
    switch (item.currencyType) {
      case CurrencyType.coins:
        return coins >= item.price;
      case CurrencyType.gems:
        return gems >= item.price;
      case CurrencyType.xp:
        return xp >= item.price;
    }
  }

  /// Deduct cost from wallet
  PlayerWallet deduct(ShopItem item) {
    if (!canAfford(item)) {
      throw InsufficientFundsException('Cannot afford ${item.name}');
    }

    switch (item.currencyType) {
      case CurrencyType.coins:
        return PlayerWallet(coins: coins - item.price, gems: gems, xp: xp);
      case CurrencyType.gems:
        return PlayerWallet(coins: coins, gems: gems - item.price, xp: xp);
      case CurrencyType.xp:
        return PlayerWallet(coins: coins, gems: gems, xp: xp - item.price);
    }
  }

  /// Add currency to wallet
  PlayerWallet add({int coins = 0, int gems = 0, int xp = 0}) {
    return PlayerWallet(
      coins: this.coins + coins,
      gems: this.gems + gems,
      xp: this.xp + xp,
    );
  }

  Map<String, dynamic> toJson() {
    return {'coins': coins, 'gems': gems, 'xp': xp};
  }

  factory PlayerWallet.fromJson(Map<String, dynamic> json) {
    return PlayerWallet(
      coins: json['coins'] ?? 0,
      gems: json['gems'] ?? 0,
      xp: json['xp'] ?? 0,
    );
  }
}

/// Exception for insufficient funds
class InsufficientFundsException implements Exception {
  final String message;

  const InsufficientFundsException(this.message);

  @override
  String toString() => 'InsufficientFundsException: $message';
}
