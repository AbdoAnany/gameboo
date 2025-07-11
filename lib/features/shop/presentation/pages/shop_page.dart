import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        child: Row(
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
              Icons.confirmation_number,
              'Tickets',
              wallet.tickets.toString(),
              Colors.purple,
            ),
          ],
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
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
                  ),
                  child: Center(
                    child: Icon(
                      _getItemIcon(item.type),
                      size: 48.w,
                      color: Colors.white,
                    ),
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
}
