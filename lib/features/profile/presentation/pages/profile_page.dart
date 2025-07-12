import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/profile_cubit.dart';
import 'activity_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile when the page is first built
    // context.read<ProfileCubit>().loadProfile();
  }

  Future<void> _onRefresh() async {
    await context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Profile'),
            backgroundColor: Colors.transparent,
            floating: true,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal:  20.w),
            sliver: BlocBuilder<ProfileCubit, ProfileState>(

              builder: (context, state) {
                if (state is ProfileLoaded) {
                  final profile = state.profile;
                  final progress = profile.progressModel;
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      GlassCard(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _buildProfileAvatar(context, rank: profile.rank),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.username,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Rank: ${profile.rank.name}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),


                              ],
                            ),
                            SizedBox(height: 16.h),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeInOutCubic,
                              tween: Tween<double>(begin: 0, end: progress.progressPercent),
                              builder: (context, animatedPercent, child) {
                                return GlassXPProgressBar(
                                  currentXP:

                                  (progress.previousLevelXP +
                                      (progress.nextLevelXP -
                                          progress.previousLevelXP) *
                                          animatedPercent)
                                      .round(),
                                  maxXP: progress.nextLevelXP,
                                  level: progress.currentLevel,
                                  title: 'Progress',
                                  height: 60.h,
                                  showXPNumbers: true,
                                  showLevel: true,
                                  animationDuration: const Duration(milliseconds: 800),
                                );
                              },
                            ),

                            SizedBox(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ProfileStat(
                                  label: 'Activity',
                                  value: state.profile.activityHistory.length.toString(),
                                ),
                                _ProfileStat(
                                  label: 'Wins',
                                  value: state.profile.totalWins.toString(),
                                ),
                                _ProfileStat(
                                  label: 'Badges',
                                  value: state.profile.earnedBadges.length
                                      .toString(),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            // Wallet Info
                            GlassContainer(
                              padding: EdgeInsets.all(12.w),

                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color: Colors.amber,
                                        size: 20.w,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${state.profile.coins}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 20.h,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.diamond,
                                        color: Colors.purple,
                                        size: 20.w,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${state.profile.gems}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Inventory Section
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: 16.h),
                            Container(
                              height: 120.h,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: state.profile.ownedShopItems.isEmpty
                                  ? Center(
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.white.withOpacity(0.5),
                                      size: 32.w,
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'No items yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                        color: Colors.white.withOpacity(
                                          0.6,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Visit the shop to get items!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: Colors.white.withOpacity(
                                          0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : Padding(
                                padding: EdgeInsets.all(12.w),
                                child: GridView.builder(
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    crossAxisSpacing: 8.w,
                                    mainAxisSpacing: 8.h,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount:
                                  state.profile.ownedShopItems.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                    state.profile.ownedShopItems[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20.w,
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            item.length > 6
                                                ? '${item.substring(0, 6)}...'
                                                : item,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontSize: 8.sp,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(height: 16.h),
                            _SettingsItem(
                              icon: Icons.shopping_bag,
                              title: 'Shop',
                              onTap: () {
                                Navigator.pushNamed(context, '/shop');
                              },
                            ),
                            // _SettingsItem(
                            //   icon: Icons.notifications_outlined,
                            //   title: 'Notifications',
                            //   onTap: () {},
                            // ),
                            _SettingsItem(
                              icon: Icons.history,
                              title: 'Activity History',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    const ActivityHistoryPage(),
                                  ),
                                );
                              },
                            ),
                            BlocBuilder<ThemeCubit, ThemeState>(
                              builder: (context, themeState) {
                                final currentTheme = themeState is ThemeChanged
                                    ? themeState.themeMode
                                    : ThemeMode.system;

                                final isDarkMode =
                                    currentTheme == ThemeMode.dark ||
                                        (currentTheme == ThemeMode.system &&
                                            Theme.of(context).brightness ==
                                                Brightness.dark);

                                return _SettingsItem(
                                  icon: isDarkMode
                                      ? Icons.light_mode_outlined
                                      : Icons.dark_mode_outlined,
                                  title: isDarkMode
                                      ? 'Switch to Light Mode'
                                      : 'Switch to Dark Mode',
                                  onTap: () {
                                    context.read<ThemeCubit>().toggleTheme();
                                  },
                                );
                              },
                            ),
                            // _SettingsItem(
                            //   icon: Icons.share_outlined,
                            //   title: 'Share Profile',
                            //   onTap: () {},
                            // ),
                          ],
                        ),
                      ),
                    ]),
                  );
                }
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileAvatar(
      BuildContext context, {
        required UserRankType rank,
      }) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: AssetImage(getBadgeAsset(rank))),
        // gradient: AppTheme.primaryGradient,
      ),
      // child: Icon(Icons.person, size: 25.w, color: Colors.white),
    );
  }
}


class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
