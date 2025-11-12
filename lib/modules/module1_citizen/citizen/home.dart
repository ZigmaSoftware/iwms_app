import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

// Layered imports
import '../../../core/di.dart';
import '../../../core/geofence_config.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../logic/theme/theme_cubit.dart';
import '../../../logic/vehicle_tracking/vehicle_bloc.dart';
import '../../../router/app_router.dart';
import '../../../shared/services/notification_service.dart';

// Import local files (now siblings) for the actual pages, though GoRouter typically uses paths

// --- 1. HOME SCREEN (Onboarding Completion View) ---

class HomeScreen extends StatelessWidget {
  final String userName;

  const HomeScreen({
    super.key,
    required this.userName,
  });

  // Helper widget to display the logo
  Widget _imageAsset(String fileName,
      {required double width, required double height}) {
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
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: primaryColor, width: 2),
                    textStyle: theme.textTheme.labelLarge
                        ?.copyWith(color: primaryColor),
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
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: primaryColor, width: 2),
                    textStyle: theme.textTheme.labelLarge
                        ?.copyWith(color: primaryColor),
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

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key, required this.userName});

  final String userName;

  static const Color _darkBackground = Color(0xFF0F3D2E);
  static const Color _darkSurface = Color(0xFF1A4C38);
  static const Color _lightBackground = Color(0xFFF6FBF4);

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  WastePeriod _selectedPeriod = WastePeriod.daily;

  final Map<WastePeriod, _WasteStats> _wasteStats = const {
    WastePeriod.daily:
        _WasteStats(dry: '2.3 kg', wet: '1.9 kg', mixed: '0.6 kg'),
    WastePeriod.monthly:
        _WasteStats(dry: '58.0 kg', wet: '43.0 kg', mixed: '12.0 kg'),
    WastePeriod.yearly:
        _WasteStats(dry: '690 kg', wet: '510 kg', mixed: '138 kg'),
  };

  late final NotificationService _notificationService;
  final List<_CitizenAlert> _alerts = [];
  bool _hasUnreadNotifications = false;
  bool _wasVehicleInsideGamma = false;
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _notificationService = getIt<NotificationService>();
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
  }

  Widget _buildCollectionStatsCard(
    BuildContext context, {
    required bool isDarkMode,
    required Color textColor,
    required Color secondaryTextColor,
    required Color highlightColor,
    required _WasteStats stats,
  }) {
    final theme = Theme.of(context);
    final cards = [
      _WasteCardData(
        label: 'Dry Waste',
        value: stats.dry,
        assetPath: 'assets/cards/drywaste.png',
      ),
      _WasteCardData(
        label: 'Wet Waste',
        value: stats.wet,
        assetPath: 'assets/cards/wetwaste.png',
      ),
      _WasteCardData(
        label: 'Mixed Waste',
        value: stats.mixed,
        assetPath: 'assets/cards/mixedwaste.png',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Collection Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Pick a date',
              onPressed: () => _pickDate(context),
              icon: Icon(
                Icons.calendar_month_outlined,
                color: highlightColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: WastePeriod.values.map((period) {
            final isSelected = _selectedPeriod == period;
            return ChoiceChip(
              label: Text(_periodLabel(period)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                }
              },
              selectedColor: highlightColor,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : textColor,
                fontWeight: FontWeight.w600,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 2,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 152,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            padding: const EdgeInsets.only(right: 12),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _WasteImageCard(data: cards[index]);
            },
          ),
        ),
      ],
    );
  }

  String _periodLabel(WastePeriod period) {
    switch (period) {
      case WastePeriod.daily:
        return 'Daily';
      case WastePeriod.monthly:
        return 'Monthly';
      case WastePeriod.yearly:
        return 'Yearly';
    }
  }

  void _evaluateGammaGeofence(
    BuildContext listenContext,
    VehicleLoaded state,
  ) {
    final hasVehicleInside =
        state.vehicles.any((vehicle) => _isInsideGammaFence(vehicle));

    if (hasVehicleInside && !_wasVehicleInsideGamma) {
      const message =
          'Upcoming collection: our truck is approaching ${GammaGeofenceConfig.name}. '
          'Please segregate your dry, wet and mixed waste for pickup.';

      if (mounted) {
        setState(() {
          _alerts.insert(
            0,
            _CitizenAlert(
              title: 'Collector arriving soon',
              message: message,
              timestamp: DateTime.now(),
            ),
          );
          _hasUnreadNotifications = true;
          _bannerDismissed = false;
        });
      }

      _notificationService.showCollectorNearbyNotification(message: message);

      if (mounted) {
        final theme = Theme.of(listenContext);
        ScaffoldMessenger.of(listenContext)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.primary,
              content: Text(
                'Next collection is nearing ${GammaGeofenceConfig.name}. '
                'Please segregate your waste.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
      }
    }

    _wasVehicleInsideGamma = hasVehicleInside;
  }

  bool _isInsideGammaFence(VehicleModel vehicle) {
    final position = LatLng(vehicle.latitude, vehicle.longitude);
    if (GammaGeofenceConfig.contains(position)) {
      return true;
    }

    final address = vehicle.address?.toLowerCase() ?? '';
    final bool flaggedByProvider = vehicle.isInsideGeofence &&
        address.contains(GammaGeofenceConfig.addressHint);

    return flaggedByProvider && GammaGeofenceConfig.isNear(position);
  }

  Future<void> _openNotificationsSheet(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _hasUnreadNotifications = false;
    });

    final theme = Theme.of(context);

    if (_alerts.isEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'You are all caught up!',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We will alert you as soon as a collection vehicle enters '
                '${GammaGeofenceConfig.name}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).padding.bottom;
        return FractionallySizedBox(
          heightFactor: 0.65,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              24,
              20,
              20 + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _alerts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final alert = _alerts[index];
                      final timestampLabel =
                          DateFormat('MMM d, h:mm a').format(alert.timestamp);

                      return _NotificationTile(
                        alert: alert,
                        timestampLabel: timestampLabel,
                        onTrack: () {
                          Navigator.of(sheetContext).pop();
                          _navigateToMap();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToMap() {
    if (!mounted) return;
    setState(() {
      _hasUnreadNotifications = false;
    });
    context.go(AppRoutePaths.citizenMap);
  }

  Widget _buildNotificationBell(
    BuildContext context, {
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final hasAlerts = _alerts.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            border: Border.all(color: borderColor),
          ),
          child: IconButton(
            icon: Icon(
              hasAlerts
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_rounded,
            ),
            color: iconColor,
            tooltip: 'Notifications',
            onPressed: () {
              _openNotificationsSheet(context);
            },
          ),
        ),
        if (_hasUnreadNotifications)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isDarkMode
        ? CitizenDashboard._darkBackground
        : CitizenDashboard._lightBackground;
    final surfaceColor =
        isDarkMode ? CitizenDashboard._darkSurface : Colors.white;
    final outlineColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final highlightColor =
        isDarkMode ? colorScheme.secondary : colorScheme.primary;

    final stats = _wasteStats[_selectedPeriod]!;

    final quickActions = [
      _QuickAction(
        label: 'Collection Details',
        assetPath: 'assets/icons/collection_details.png',
        onTap: () => context.go(AppRoutePaths.citizenDriverDetails),
      ),
      _QuickAction(
        label: 'Collection History',
        assetPath: 'assets/icons/monthly_stats.png',
        onTap: () => context.go(AppRoutePaths.citizenHistory),
      ),
      _QuickAction(
        label: 'Raise Grievance',
        assetPath: 'assets/icons/raise_grievance.png',
        onTap: () => context.go(AppRoutePaths.citizenChatbot),
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

    return BlocListener<VehicleBloc, VehicleState>(
        listenWhen: (previous, current) => current is VehicleLoaded,
        listener: (context, state) {
          if (state is VehicleLoaded) {
            _evaluateGammaGeofence(context, state);
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.go(AppRoutePaths.citizenProfile),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: surfaceColor,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/icons/profile.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${widget.userName}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildNotificationBell(
                        context,
                        iconColor: highlightColor,
                        backgroundColor: surfaceColor,
                        borderColor: outlineColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_alerts.isNotEmpty && !_bannerDismissed) ...[
                    _NotificationBanner(
                      alert: _alerts.first,
                      accentColor: highlightColor,
                      onTrack: _navigateToMap,
                      onViewDetails: () {
                        _openNotificationsSheet(context);
                      },
                      onDismiss: () {
                        setState(() {
                          _bannerDismissed = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _SectionCard(
                    surfaceColor: surfaceColor,
                    outlineColor: outlineColor,
                    isDarkMode: isDarkMode,
                    child: _buildCollectionStatsCard(
                      context,
                      isDarkMode: isDarkMode,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      highlightColor: highlightColor,
                      stats: stats,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.go(AppRoutePaths.citizenTrack),
                          icon: Icon(Icons.location_searching,
                              color: highlightColor),
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
                        child: FilledButton.icon(
                          onPressed: () =>
                              context.go(AppRoutePaths.citizenDriverDetails),
                          icon: const Icon(Icons.schedule),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: highlightColor,
                          ),
                          label: Text(
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
        ));
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required Color accent,
    required bool isDarkMode,
  }) {
    final theme = Theme.of(context);
    final Color backgroundTint = isDarkMode
        ? accent.withValues(alpha: 0.28)
        : accent.withValues(alpha: 0.14);
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

enum WastePeriod { daily, monthly, yearly }

class _WasteStats {
  const _WasteStats({
    required this.dry,
    required this.wet,
    required this.mixed,
  });

  final String dry;
  final String wet;
  final String mixed;
}

class _WasteCardData {
  const _WasteCardData({
    required this.label,
    required this.value,
    required this.assetPath,
  });

  final String label;
  final String value;
  final String assetPath;
}

class _WasteImageCard extends StatelessWidget {
  const _WasteImageCard({required this.data});

  final _WasteCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 172,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data.assetPath,
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x14000000),
                    Color(0x8F000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
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

class _CitizenAlert {
  const _CitizenAlert({
    required this.title,
    required this.message,
    required this.timestamp,
  });

  final String title;
  final String message;
  final DateTime timestamp;
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({
    required this.alert,
    required this.accentColor,
    required this.onTrack,
    required this.onViewDetails,
    this.onDismiss,
  });

  final _CitizenAlert alert;
  final Color accentColor;
  final VoidCallback onTrack;
  final VoidCallback onViewDetails;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp =
        DateFormat('MMM d, h:mm a').format(alert.timestamp).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION ALERT • $timestamp',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minHeight: 32, minWidth: 32),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onTrack,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.directions_bus_filled_outlined),
                label: const Text('Track'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onViewDetails,
                child: const Text('View details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.alert,
    required this.timestampLabel,
    required this.onTrack,
  });

  final _CitizenAlert alert;
  final String timestampLabel;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseSurface = theme.colorScheme.surfaceContainerHighest;
    final background = isDark
        ? baseSurface.withValues(alpha: 0.28)
        : baseSurface.withValues(alpha: 0.7);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timestampLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            alert.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: onTrack,
              icon: const Icon(Icons.route_outlined),
              label: const Text('Track'),
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
  });

  final List<_QuickAction> actions;
  final bool isDarkMode;
  final Color surfaceColor;
  final Color textColor;

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
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    action.assetPath,
                    fit: BoxFit.cover,
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
