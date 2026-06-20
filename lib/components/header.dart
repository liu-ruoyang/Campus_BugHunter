// This component file defines the shared profile bar shown above the main app tabs.
// It loads the current profile name and wallet balance without pinning itself to the viewport.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/profile/profile_cubit.dart';
import '../bloc/profile/profile_state.dart';
import '../theme/app_theme.dart';

// HomeHeader creates its own ProfileCubit to fetch user data for the greeting area.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  // The build method combines profile state, avatar, username, and wallet balance in one header row.
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(bottom: BorderSide(color: colors.border)),
        ),
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            return Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primary,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.username.isEmpty ? 'User' : state.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Campus BugHunter',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        color: colors.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'RM ${state.wallet.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
