import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../router/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.userName,
  });

  final String userName;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryText = isDarkMode ? Colors.white70 : Colors.black54;
    final highlightColor =
        isDarkMode ? colorScheme.secondary : colorScheme.primary;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0F3D2E) : const Color(0xFFF6FBF4);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bgd.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Text(
                        'Profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/profile.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, $userName',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your account and collection preferences',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  _ProfileOptionTile(
                    icon: Icons.description_outlined,
                    label: 'Collection Details',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () => context.go(AppRoutePaths.citizenDriverDetails),
                  ),
                  _ProfileOptionTile(
                    icon: Icons.history,
                    label: 'Collection History & Weighment',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () => context.go(AppRoutePaths.citizenHistory),
                  ),
                  _ProfileOptionTile(
                    icon: Icons.location_on_outlined,
                    label: 'Track My Waste',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () => context.go(AppRoutePaths.citizenTrack),
                  ),
                  _ProfileOptionTile(
                    icon: Icons.star_rate_outlined,
                    label: 'Rate Last Collection',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () => _showComingSoon(context, 'Rating feature'),
                  ),
                  _ProfileOptionTile(
                    icon: Icons.payments_outlined,
                    label: 'View Charges & Fines',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () =>
                        _showComingSoon(context, 'Charges & fines section'),
                  ),
                  _ProfileThemeToggle(
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    secondaryText: secondaryText,
                    highlightColor: highlightColor,
                  ),
                  _ProfileOptionTile(
                    icon: Icons.feedback_outlined,
                    label: 'Raise Grievance (Help Desk)',
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                    highlightColor: highlightColor,
                    onTap: () =>
                        _showComingSoon(context, 'Grievance redressal module'),
                  ),
                  const SizedBox(height: 12),
                  _LogoutTile(
                    textColor: textColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  const _ProfileOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.isDarkMode,
    required this.highlightColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final bool isDarkMode;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final Color tileColor =
        isDarkMode ? const Color(0xFF1A4C38) : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isDarkMode ? 0 : 2,
      color: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: highlightColor),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDarkMode ? Colors.white54 : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileThemeToggle extends StatelessWidget {
  const _ProfileThemeToggle({
    required this.isDarkMode,
    required this.textColor,
    required this.secondaryText,
    required this.highlightColor,
  });

  final bool isDarkMode;
  final Color textColor;
  final Color secondaryText;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final Color tileColor =
        isDarkMode ? const Color(0xFF1A4C38) : Colors.white;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isDarkMode ? 0 : 2,
      color: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile.adaptive(
        value: isDarkMode,
        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
        secondary: Icon(Icons.dark_mode_outlined, color: highlightColor),
        title: Text(
          'Dark Mode',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          'Switch between light and dark experiences',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondaryText,
              ),
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => highlightColor,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? highlightColor.withValues(alpha: 0.5)
              : highlightColor.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({
    required this.textColor,
    required this.isDarkMode,
  });

  final Color textColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final Color tileColor =
        isDarkMode ? const Color(0xFF1A4C38) : Colors.white;

    return Card(
      elevation: isDarkMode ? 0 : 2,
      color: tileColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: Text(
          'Logout',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
        ),
        onTap: () {
          context.read<AuthBloc>().add(AuthLogoutRequested());
        },
      ),
    );
  }
}
