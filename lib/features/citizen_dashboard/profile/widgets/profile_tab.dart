import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../logic/auth/auth_bloc.dart';
import '../../../../logic/auth/auth_event.dart';
import '../../../../logic/theme/theme_cubit.dart';
import '../../../../router/app_router.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.headerHeight,
    required this.headerGradientColors,
    required this.normalizedName,
    required this.highlightColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  final double headerHeight;
  final List<Color> headerGradientColors;
  final String normalizedName;
  final Color highlightColor;
  final Color textColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authBloc = context.read<AuthBloc>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: headerHeight * 0.68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: headerGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hi, $normalizedName',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your account and collection preferences.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              _ProfileTile(
                icon: Icons.description_outlined,
                label: 'Collection Details',
                onTap: () => context.push(AppRoutePaths.citizenDriverDetails),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _ProfileTile(
                icon: Icons.history,
                label: 'Collection History & Weighment',
                onTap: () => context.push(AppRoutePaths.citizenHistory),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _ProfileTile(
                icon: Icons.location_on_outlined,
                label: 'Track My Waste',
                onTap: () => context.push(AppRoutePaths.citizenMap),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _ProfileTile(
                icon: Icons.feedback_outlined,
                label: 'Raise Grievance (Help Desk)',
                onTap: () => context.push(AppRoutePaths.citizenGrievanceChat),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _themeToggleTile(context, highlightColor, secondaryTextColor),
              const SizedBox(height: 12),
              Card(
                elevation: theme.brightness == Brightness.dark ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Logout',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => authBloc.add(AuthLogoutRequested()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _themeToggleTile(
    BuildContext context,
    Color highlightColor,
    Color secondaryText,
  ) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: isDarkMode ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile.adaptive(
        value: isDarkMode,
        onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
        secondary: Icon(Icons.dark_mode_outlined, color: highlightColor),
        title: Text(
          'Dark Mode',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Switch between light and dark experiences',
          style: theme.textTheme.bodySmall?.copyWith(
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

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.textColor,
    required this.highlightColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: highlightColor),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.brightness == Brightness.dark
              ? Colors.white54
              : Colors.black26,
        ),
        onTap: onTap,
      ),
    );
  }
}
