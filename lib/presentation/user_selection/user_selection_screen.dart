// lib/presentation/user_selection/user_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iwms_citizen_app/router/app_router.dart'; // We will create this

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          color: const Color(0xFF21381B),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: const SafeArea(
            bottom: false,
            child: SizedBox.expand(),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bgd.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Welcome to IWMS",
              style: textTheme.headlineMedium?.copyWith(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Who are you?",
              style: textTheme.titleLarge?.copyWith(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            const SizedBox(height: 48),

            // --- User Roles ---
            _UserRoleCard(
              icon: Icons.person,
              title: "Citizen",
              onTap: () {
                // Navigate to Citizen Login
                context.push(AppRoutePaths.citizenLogin);
              },
              iconColor: primaryColor,
            ),
            _UserRoleCard(
              icon: Icons.build,
              title: "Operator",
              onTap: () {
                // Placeholder
                _showComingSoon(context);
              },
              iconColor: primaryColor,
            ),
            _UserRoleCard(
              icon: Icons.admin_panel_settings,
              title: "Admin",
              onTap: () {
                // Placeholder
                _showComingSoon(context);
              },
              iconColor: primaryColor,
            ),
            _UserRoleCard(
              icon: Icons.security,
              title: "Super Admin",
              onTap: () {
                // Placeholder
                _showComingSoon(context);
              },
              iconColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This module is coming soon!'),
        backgroundColor: Colors.grey,
      ),
    );
  }
}

class _UserRoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;

  const _UserRoleCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
