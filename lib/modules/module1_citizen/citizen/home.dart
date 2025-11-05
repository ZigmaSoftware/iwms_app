import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Layered imports
import '../../../logic/theme/theme_cubit.dart';
import '../../../router/app_router.dart';

// Import local files (now siblings) for the actual pages, though GoRouter typically uses paths

// --- 1. HOME SCREEN (Onboarding Completion View) ---

class HomeScreen extends StatelessWidget {
  final String userName; 

  const HomeScreen({
    super.key,
    required this.userName,
  });
  
  // Helper widget to display the logo
  Widget _imageAsset(String fileName, {required double width, required double height}) {
    return Image.asset(
      'assets/images/$fileName',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  void _navigateToDashboard(BuildContext context) {
    // GoRouter handles the navigation and stack manipulation automatically
    context.go(AppRoutePaths.citizenHome);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textColor = colorScheme.onSurface;
    final mutedText = textColor.withValues(alpha: 0.7);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registration Successful',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bgd.jpg'),
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- WELCOME MESSAGE ---
              Text(
                'Welcome, $userName!',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: primaryColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 40),
              
              // Display the actual logo
              _imageAsset('logo.png', width: 80, height: 80), 
              const SizedBox(height: 20),

              Text(
                'Registration Complete!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your unique QR code is now active for waste collection verification.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: mutedText),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.qr_code_2, color: primaryColor),
                  label: Text(
                    'View My Collection QR Code',
                    style: theme.textTheme.labelLarge?.copyWith(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: primaryColor, width: 2),
                    textStyle: theme.textTheme.labelLarge?.copyWith(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 10),

               SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.feedback_outlined, color: primaryColor),
                  label: Text(
                    'Raise a Grievance',
                    style: theme.textTheme.labelLarge?.copyWith(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: primaryColor, width: 2),
                    textStyle: theme.textTheme.labelLarge?.copyWith(color: primaryColor),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // --- NAVIGATION BUTTON ---
              TextButton(
                onPressed: () {
                  context.go(AppRoutePaths.citizenHome);
                },
                child: Text(
                  'Skip to Dashboard',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 2. CITIZEN DASHBOARD (The actual app home with drawer) ---

class CitizenDashboard extends StatelessWidget {
  const CitizenDashboard({super.key, required this.userName});

  final String userName;

  static const Color _darkBackground = Color(0xFF0F3D2E);
  static const Color _darkSurface = Color(0xFF1A4C38);
  static const Color _lightBackground = Color(0xFFF6FBF4);

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isDarkMode ? _darkBackground : _lightBackground;
    final surfaceColor = isDarkMode ? _darkSurface : Colors.white;
    final outlineColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor =
        isDarkMode ? Colors.white70 : Colors.black54;
    final highlightColor =
        isDarkMode ? colorScheme.secondary : colorScheme.primary;

    final quickActions = [
      _QuickAction(
        label: 'Collection Details',
        assetPath: 'assets/icons/collection_details.png',
        onTap: () => context.go(AppRoutePaths.citizenDriverDetails),
      ),
      _QuickAction(
        label: 'Track Waste',
        assetPath: 'assets/icons/collection.png',
        onTap: () => context.go(AppRoutePaths.citizenTrack),
      ),
      _QuickAction(
        label: 'Collection History',
        assetPath: 'assets/icons/monthly_stats.png',
        onTap: () => context.go(AppRoutePaths.citizenHistory),
      ),
      _QuickAction(
        label: 'Raise Grievance',
        assetPath: 'assets/icons/raise_grievance.png',
        onTap: () => _showComingSoon(context, 'Grievance module'),
      ),
      _QuickAction(
        label: 'Rate Collector',
        assetPath: 'assets/icons/rate_collector.png',
        onTap: () => _showComingSoon(context, 'Rating feature'),
      ),
      _QuickAction(
        label: 'Profile',
        assetPath: 'assets/icons/profile.png',
        onTap: () => context.go(AppRoutePaths.citizenProfile),
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $userName',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Here is your waste collection summary',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(AppRoutePaths.citizenProfile),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                        border: Border.all(color: outlineColor),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/icons/profile.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionCard(
                surfaceColor: surfaceColor,
                outlineColor: outlineColor,
                isDarkMode: isDarkMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Collection QR Code',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Show this QR code to the collector during pickup.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? surfaceColor.withValues(alpha: 0.6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: outlineColor),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.asset(
                          'assets/images/qr.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutePaths.citizenTrack),
                            icon: Icon(Icons.location_searching, color: highlightColor),
                            label: Text(
                              'Track Waste',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: highlightColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: highlightColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.go(AppRoutePaths.citizenDriverDetails),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: highlightColor,
                            ),
                            child: Text(
                              'Next Pickup',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              _QuickActionGrid(
                actions: quickActions,
                isDarkMode: isDarkMode,
                surfaceColor: surfaceColor,
                textColor: textColor,
                outlineColor: outlineColor,
              ),
              const SizedBox(height: 28),
              Text(
                'Monthly Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Dry Waste',
                      value: '12.5 kg',
                      accent: Colors.blue,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Wet Waste',
                      value: '25.0 kg',
                      accent: Colors.green,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Collections',
                      value: '8 / month',
                      accent: Colors.deepOrange,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Compliance',
                      value: '4.8 ?',
                      accent: Colors.purple,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color accent,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final Color backgroundTint =
        isDarkMode ? accent.withValues(alpha: 0.28) : accent.withValues(alpha: 0.14);
    final Color labelColor = isDarkMode ? Colors.white70 : Colors.black87;
    final Color valueColor = isDarkMode ? Colors.white : accent;

    return Container(
      decoration: BoxDecoration(
        color: backgroundTint,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.actions,
    required this.isDarkMode,
    required this.surfaceColor,
    required this.textColor,
    required this.outlineColor,
  });

  final List<_QuickAction> actions;
  final bool isDarkMode;
  final Color surfaceColor;
  final Color textColor;
  final Color outlineColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: action.onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                    Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? surfaceColor.withValues(alpha: 0.6)
                        : surfaceColor,
                    border: Border.all(color: outlineColor),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    action.assetPath,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.surfaceColor,
    required this.outlineColor,
    required this.isDarkMode,
  });

  final Widget child;
  final Color surfaceColor;
  final Color outlineColor;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineColor),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.assetPath,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final VoidCallback onTap;
}
