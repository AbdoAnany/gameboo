import 'package:equatable/equatable.dart';
import '../../../characters/domain/entities/character.dart';

enum ShopItemType { ticket, monster, character, powerup, skin }

enum CurrencyType { coins, gems, xp }

class ShopItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final ShopItemType type;
  final CurrencyType currencyType;
  final int price;
  final bool isOwned;
  final bool isLimited;
  final DateTime? expiryDate;
  final Map<String, dynamic> properties;
  final CharacterType? characterType; // For character items

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.type,
    required this.currencyType,
    required this.price,
    this.isOwned = false,
    this.isLimited = false,
    this.expiryDate,
    this.properties = const {},
    this.characterType,
  });

  ShopItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    ShopItemType? type,
    CurrencyType? currencyType,
    int? price,
    bool? isOwned,
    bool? isLimited,
    DateTime? expiryDate,
    Map<String, dynamic>? properties,
    CharacterType? characterType,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      currencyType: currencyType ?? this.currencyType,
      price: price ?? this.price,
      isOwned: isOwned ?? this.isOwned,
      isLimited: isLimited ?? this.isLimited,
      expiryDate: expiryDate ?? this.expiryDate,
      properties: properties ?? this.properties,
      characterType: characterType ?? this.characterType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'type': type.name,
      'currencyType': currencyType.name,
      'price': price,
      'isOwned': isOwned,
      'isLimited': isLimited,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'properties': properties,
      'characterType': characterType?.name,
    };
  }

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      type: ShopItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ShopItemType.ticket,
      ),
      currencyType: CurrencyType.values.firstWhere(
        (e) => e.name == json['currencyType'],
        orElse: () => CurrencyType.coins,
      ),
      price: json['price'] ?? 0,
      isOwned: json['isOwned'] ?? false,
      isLimited: json['isLimited'] ?? false,
      expiryDate: json['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiryDate'])
          : null,
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      characterType: json['characterType'] != null
          ? CharacterType.values.firstWhere(
              (e) => e.name == json['characterType'],
              orElse: () => CharacterType.nova,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imagePath,
    type,
    currencyType,
    price,
    isOwned,
    isLimited,
    expiryDate,
    properties,
    characterType,
  ];
}

class PlayerWallet extends Equatable {
  final int coins;
  final int gems;
  final int tickets;
  final List<String> ownedItems;

  const PlayerWallet({
    this.coins = 0,
    this.gems = 0,
    this.tickets = 0,
    this.ownedItems = const [],
  });

  PlayerWallet copyWith({
    int? coins,
    int? gems,
    int? tickets,
    List<String>? ownedItems,
  }) {
    return PlayerWallet(
      coins: coins ?? this.coins,
      gems: gems ?? this.gems,
      tickets: tickets ?? this.tickets,
      ownedItems: ownedItems ?? this.ownedItems,
    );
  }

  bool canAfford(ShopItem item) {
    switch (item.currencyType) {
      case CurrencyType.coins:
        return coins >= item.price;
      case CurrencyType.gems:
        return gems >= item.price;
      case CurrencyType.xp:
        return true; // XP check would be done against profile XP
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'coins': coins,
      'gems': gems,
      'tickets': tickets,
      'ownedItems': ownedItems,
    };
  }

  factory PlayerWallet.fromJson(Map<String, dynamic> json) {
    return PlayerWallet(
      coins: json['coins'] ?? 0,
      gems: json['gems'] ?? 0,
      tickets: json['tickets'] ?? 0,
      ownedItems: List<String>.from(json['ownedItems'] ?? []),
    );
  }

  @override
  List<Object?> get props => [coins, gems, tickets, ownedItems];
}
