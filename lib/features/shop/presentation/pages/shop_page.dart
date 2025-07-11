import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../cubit/shop_cubit.dart';
import '../../domain/entities/shop_item.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({Key? key}) : super(key: key);

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  ShopItemType? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Load shop data from profile when page opens
    final profileState = context.read<ProfileCubit>().state;
    if (profileState is ProfileLoaded) {
      final wallet = PlayerWallet(
        coins: profileState.profile.coins,
        gems: profileState.profile.gems,
        ownedItems: profileState.profile.ownedShopItems,
      );
      context.read<ShopCubit>().loadShop(wallet: wallet);
    } else {
      context.read<ShopCubit>().loadShop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'GameBoo Shop',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48.w), // Balance the back button
                  ],
                ),
              ),

              // Wallet Info
              BlocBuilder<ShopCubit, ShopState>(
                builder: (context, shopState) {
                  if (shopState is ShopLoaded) {
                    return _buildWalletInfo(context, shopState.wallet);
                  }
                  return const SizedBox.shrink();
                },
              ),

              SizedBox(height: 16.h),

              // Category Filter
              _buildCategoryFilter(),

              SizedBox(height: 16.h),

              // Shop Content
              Expanded(
                child: BlocConsumer<ShopCubit, ShopState>(
                  listener: (context, state) {
                    if (state is ShopError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is ShopPurchaseSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Successfully purchased ${state.item.name}!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is ShopLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ShopLoaded) {
                      return _buildShopGrid(context, state.items, state.wallet);
                    } else if (state is ShopError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.w,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              state.message,
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletInfo(BuildContext context, PlayerWallet wallet) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GlassCard(
        padding: EdgeInsets.all(16.w),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            int userXP = 0;
            if (profileState is ProfileLoaded) {
              userXP = profileState.profile.xp;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCurrencyInfo(
                  context,
                  Icons.monetization_on,
                  'Coins',
                  wallet.coins.toString(),
                  Colors.amber,
                ),
                _buildCurrencyInfo(
                  context,
                  Icons.diamond,
                  'Gems',
                  wallet.gems.toString(),
                  Colors.blue,
                ),
                _buildCurrencyInfo(
                  context,
                  Icons.star,
                  'XP',
                  userXP.toString(),
                  Colors.purple,
                ),
                _buildCurrencyInfo(
                  context,
                  Icons.confirmation_number,
                  'Tickets',
                  wallet.tickets.toString(),
                  Colors.indigo,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyInfo(
    BuildContext context,
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24.w),
        SizedBox(height: 4.h),
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildShopGrid(
    BuildContext context,
    List<ShopItem> items,
    PlayerWallet wallet,
  ) {
    // Filter items based on selected category
    final filteredItems = _selectedCategory == null
        ? items
        : items.where((item) => item.type == _selectedCategory).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: filteredItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64.w,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No items in this category',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 0.75,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildShopItemCard(context, item, wallet);
              },
            ),
    );
  }

  Widget _buildShopItemCard(
    BuildContext context,
    ShopItem item,
    PlayerWallet wallet,
  ) {
    final theme = Theme.of(context);
    final isOwned = wallet.ownedItems.contains(item.id);

    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        int userXP = 0;
        if (profileState is ProfileLoaded) {
          userXP = profileState.profile.xp;
        }

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

        return GlassCard(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: _getItemGradient(item.type),
                    boxShadow: [
                      BoxShadow(
                        color: _getItemGradient(
                          item.type,
                        ).colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Background pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _getCustomPainter(item.type),
                        ),
                      ),
                      // Main icon
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getItemIcon(item.type),
                              size: 36.w,
                              color: Colors.white,
                            ),
                            if (item.type == ShopItemType.character)
                              Text(
                                item.characterType?.name.toUpperCase() ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Rarity indicator
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _getRarityIcon(item.currencyType),
                            size: 12.w,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8.h),

              // Item Name
              Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 4.h),

              // Item Description
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 8.h),

              // Price and Buy Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCurrencyIcon(item.currencyType),
                        size: 16.w,
                        color: _getCurrencyColor(item.currencyType),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        item.price.toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getCurrencyColor(item.currencyType),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton(
                      onPressed: isOwned
                          ? null
                          : canAfford
                          ? () {
                              context.read<ShopCubit>().purchaseItem(
                                item,
                                userXP,
                              );
                              if (item.currencyType == CurrencyType.xp) {
                                context.read<ProfileCubit>().addXP(-item.price);
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOwned
                            ? Colors.green
                            : canAfford
                            ? theme.colorScheme.primary
                            : Colors.grey,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        isOwned
                            ? 'Owned'
                            : canAfford
                            ? 'Buy'
                            : 'No ${item.currencyType.name}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      null, // All items
      ShopItemType.ticket,
      ShopItemType.monster,
      ShopItemType.character,
      ShopItemType.powerup,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SizedBox(
        height: 40.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => SizedBox(width: 8.w),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategory == category;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  color: isSelected
                      ? null
                      : Theme.of(context).colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category == null ? Icons.apps : _getItemIcon(category),
                      size: 16.w,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      category == null ? 'All' : _getCategoryName(category),
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _getCategoryName(ShopItemType type) {
    switch (type) {
      case ShopItemType.ticket:
        return 'Tickets';
      case ShopItemType.monster:
        return 'Monsters';
      case ShopItemType.character:
        return 'Characters';
      case ShopItemType.powerup:
        return 'Power-ups';
      case ShopItemType.skin:
        return 'Skins';
    }
  }

  LinearGradient _getItemGradient(ShopItemType type) {
    switch (type) {
      case ShopItemType.ticket:
        return const LinearGradient(colors: [Colors.amber, Colors.orange]);
      case ShopItemType.monster:
        return const LinearGradient(colors: [Colors.red, Colors.deepOrange]);
      case ShopItemType.character:
        return const LinearGradient(colors: [Colors.blue, Colors.indigo]);
      case ShopItemType.powerup:
        return const LinearGradient(colors: [Colors.green, Colors.teal]);
      case ShopItemType.skin:
        return const LinearGradient(colors: [Colors.purple, Colors.pink]);
    }
  }

  IconData _getItemIcon(ShopItemType type) {
    switch (type) {
      case ShopItemType.ticket:
        return Icons.confirmation_number;
      case ShopItemType.monster:
        return Icons.pets;
      case ShopItemType.character:
        return Icons.person;
      case ShopItemType.powerup:
        return Icons.flash_on;
      case ShopItemType.skin:
        return Icons.palette;
    }
  }

  IconData _getCurrencyIcon(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return Icons.monetization_on;
      case CurrencyType.gems:
        return Icons.diamond;
      case CurrencyType.xp:
        return Icons.star;
    }
  }

  Color _getCurrencyColor(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return Colors.amber;
      case CurrencyType.gems:
        return Colors.blue;
      case CurrencyType.xp:
        return Colors.purple;
    }
  }

  CustomPainter? _getCustomPainter(ShopItemType type) {
    switch (type) {
      case ShopItemType.ticket:
        return TicketPatternPainter();
      case ShopItemType.monster:
        return MonsterPatternPainter();
      case ShopItemType.character:
        return CharacterPatternPainter();
      case ShopItemType.powerup:
        return PowerUpPatternPainter();
      case ShopItemType.skin:
        return SkinPatternPainter();
    }
  }

  IconData _getRarityIcon(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return Icons.star_border;
      case CurrencyType.gems:
        return Icons.stars;
      case CurrencyType.xp:
        return Icons.auto_awesome;
    }
  }
}

// Custom Painters for different item types
class TicketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    // Draw dotted lines pattern like a ticket
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      for (int j = 0; j < 8; j++) {
        final x = size.width * j / 8;
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MonsterPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw claw marks pattern
    for (int i = 0; i < 3; i++) {
      final path = Path();
      final startX = size.width * 0.2 + (i * size.width * 0.2);
      path.moveTo(startX, size.height * 0.2);
      path.quadraticBezierTo(
        startX + size.width * 0.1,
        size.height * 0.5,
        startX,
        size.height * 0.8,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CharacterPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw hexagon pattern
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      if (i == 0) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      } else {
        canvas.drawLine(center, Offset(x, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PowerUpPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 2;

    // Draw lightning bolt pattern
    final path = Path();
    path.moveTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.8);
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SkinPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw diamond pattern
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final centerX = size.width * (i + 1) / 4;
        final centerY = size.height * (j + 1) / 4;
        final diamondSize = size.width * 0.05;

        final path = Path();
        path.moveTo(centerX, centerY - diamondSize);
        path.lineTo(centerX + diamondSize, centerY);
        path.lineTo(centerX, centerY + diamondSize);
        path.lineTo(centerX - diamondSize, centerY);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
