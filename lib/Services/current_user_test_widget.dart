// 📁 lib/Services/current_user_test_widget.dart
// 🧪 Test widget for CurrentUserService
// Kullanım: Herhangi bir sayfaya ekleyebilirsin

import 'package:flutter/material.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class CurrentUserTestWidget extends StatelessWidget {
  const CurrentUserTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = CurrentUserService.instance;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Row(
            children: [
              const Icon(Icons.bug_report, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'CurrentUserService Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  userService.printDebugInfo();
                  userService.forceRefresh();
                },
                tooltip: 'Force Refresh',
              ),
            ],
          ),
          const Divider(),

          // User Info (Reactive)
          Obx(() {
            final user = userService.currentUserRx.value;

            if (user == null) {
              return const _InfoRow(
                icon: Icons.person_off,
                label: 'Status',
                value: 'Not logged in',
                valueColor: Colors.red,
              );
            }

            return Column(
              children: [
                _InfoRow(
                  icon: Icons.check_circle,
                  label: 'Status',
                  value: 'Logged in',
                  valueColor: Colors.green,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.fingerprint,
                  label: 'User ID',
                  value: user.userID,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.account_circle,
                  label: 'Nickname',
                  value: user.nickname,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.person,
                  label: 'Full Name',
                  value: user.fullName,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: user.email,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: user.phoneNumber,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.image,
                  label: 'Profile Image',
                  value: user.avatarUrl.isNotEmpty ? 'Yes' : 'No',
                  valueColor:
                      user.avatarUrl.isNotEmpty ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.verified,
                  label: 'Verified',
                  value: user.isVerified ? 'Yes' : 'No',
                  valueColor: user.isVerified ? Colors.blue : Colors.grey,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.lock,
                  label: 'Private',
                  value: user.isPrivate ? 'Yes' : 'No',
                  valueColor: user.isPrivate ? Colors.orange : Colors.grey,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.remove_red_eye,
                  label: 'View Selection',
                  value: user.viewSelection == 1 ? 'Modern' : 'Classic',
                ),

                // Statistics
                const Divider(height: 24),
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Posts',
                      value: user.counterOfPosts,
                    ),
                    _StatItem(
                      label: 'Followers',
                      value: user.counterOfFollowers,
                    ),
                    _StatItem(
                      label: 'Following',
                      value: user.counterOfFollowings,
                    ),
                    _StatItem(
                      label: 'Likes',
                      value: user.counterOfLikes,
                    ),
                  ],
                ),

                // Education Info
                if (user.educationLevel.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Education',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.school,
                    label: 'Level',
                    value: user.educationLevel,
                  ),
                  if (user.universite.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.domain,
                      label: 'University',
                      value: user.universite,
                    ),
                  ],
                  if (user.bolum.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.book,
                      label: 'Department',
                      value: user.bolum,
                    ),
                  ],
                ],

                // Location Info
                if (user.locationSehir.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_city,
                    label: 'City',
                    value: user.locationSehir,
                  ),
                ],

                // Blocked Users
                if (user.blockedUsers.isNotEmpty) ...[
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.block,
                    label: 'Blocked Users',
                    value: '${user.blockedUsers.length} users',
                    valueColor: Colors.red,
                  ),
                ],
              ],
            );
          }),

          // Debug Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                userService.printDebugInfo();
                AppSnackbar(
                  '🔍 Debug Info',
                  'Check console for details',
                  backgroundColor: Colors.blue,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
              icon: const Icon(Icons.terminal),
              label: const Text('Print Debug Info to Console'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          // Cache Info
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final info = userService.getDebugInfo();
                Get.dialog(
                  AlertDialog(
                    title: const Text('Debug Info'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: info.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${e.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text('${e.value}'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Show Debug Dialog'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
