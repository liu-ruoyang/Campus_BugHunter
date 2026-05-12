import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/profile/profile_cubit.dart';
import '../bloc/profile/profile_state.dart';
import 'edit_profile.dart';
import 'reload.dart';
import 'request_record.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
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
                          Row(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const EditProfilePage(),
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    context.read<ProfileCubit>().loadProfile();
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
                              Text(
                                state.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _showMessage(context, 'Settings clicked'),
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
                        _showMessage(context, 'Helper Record');
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
