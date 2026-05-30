// This page file renders the signed-in user's profile dashboard.
// It shows profile identity, current role, wallet balance, request navigation, logout, and account deletion actions.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/home/role_cubit.dart';
import '../bloc/profile/profile_cubit.dart';
import '../bloc/profile/profile_state.dart';
import 'edit_profile.dart';
import 'helper_record.dart';
import 'reload.dart';
import 'request_record.dart';

// ProfilePage provides ProfileCubit and loads the latest profile before showing the view.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  // The build method creates the profile bloc scope and delegates visual layout to _ProfileView.
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

// _ProfileView listens to auth and profile messages while rendering all visible profile actions.
class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  // The build method composes the profile header, wallet card, role switcher, and action cards.
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            if (state.message != null) {
              _showMessage(context, state.message!);
            }
          },
        ),
        BlocListener<ProfileCubit, ProfileState>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            if (state.message != null) {
              _showMessage(context, state.message!);
            }
          },
        ),
      ],
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return Container(
            color: const Color(0xFF020617),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const EditProfilePage(),
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      context
                                          .read<ProfileCubit>()
                                          .loadProfile();
                                    },
                                    child: const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.blue,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.username,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      BlocBuilder<RoleCubit, UserRole>(
                                        builder: (context, role) {
                                          return Text(
                                            'Current role: ${role.label}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: BlocBuilder<RoleCubit, UserRole>(
                              builder: (context, role) {
                                return OutlinedButton.icon(
                                  onPressed: () =>
                                      context.read<RoleCubit>().switchRole(),
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                  label: Text(
                                    'Switch to ${role.opposite.label}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white54,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Wallet',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'RM ${state.wallet.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ReloadPage(),
                                  ),
                                );
                                if (!context.mounted) return;
                                context.read<ProfileCubit>().loadProfile();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.25,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Reload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildCard(context, 'Request Record', Icons.list, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestRecordPage(),
                          ),
                        );
                      }),
                      _buildCard(context, 'Helper Record', Icons.handshake, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HelperRecordPage(),
                          ),
                        );
                      }),
                      _buildCard(context, 'Logout', Icons.logout, () {
                        context.read<AuthCubit>().logout();
                      }),
                      _buildCard(context, 'Delete Account', Icons.delete, () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text(
                              'Are you sure you want to delete your account?\nThis action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<AuthCubit>().deleteAccount();
                                },
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // This helper builds one tappable profile action row with an icon and trailing arrow.
  Widget _buildCard(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // This helper displays simple dialog messages from auth and profile cubits.
  void _showMessage(BuildContext context, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Message'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
