import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:iconify_flutter/iconify_flutter.dart'; // Layered imports
import '../../../core/di.dart';
import '../../../core/geofence_config.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
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

  static const Color _darkBackground = Color(0xFF04120A);
  static const Color _darkSurface = Color(0xFF0B2716);
  static const Color _lightBackground = Color(0xFFEBF8EF);

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard>
    with SingleTickerProviderStateMixin {
  WastePeriod _selectedPeriod = WastePeriod.daily;
  _BottomNavItem _activeNavItem = _BottomNavItem.home;
  late final PageController _bannerPageController;
  late final AnimationController _bellController;
  late final Animation<double> _bellSwing;
  int _activeBannerIndex = 0;
  final MapController _trackMapController = MapController();
  LatLng? _lastPreviewCenter;
  final LatLng _gammaCenter = GammaGeofenceConfig.center;

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
  final List<_BannerSlide> _bannerSlides = const [
    _BannerSlide(
      chipLabel: 'Support',
      title: 'Report missed pickups instantly',
      subtitle: 'Our support desk responds within 10 mins.',
      colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
      icon: Icons.support_agent,
      backgroundImage: 'assets/banner/banner1.jpg',
      subtitleFontSize: 10,
    ),
    _BannerSlide(
      chipLabel: 'Pickups',
      title: 'Track your collector live on map',
      subtitle: 'Stay ready before the vehicle arrives.',
      colors: [Color(0xFF1B5E20), Color(0xFF2E7D5A)],
      icon: Icons.map_outlined,
      backgroundImage: 'assets/banner/banner3.jpg',
      subtitleFontSize: 10,
    ),
    _BannerSlide(
      chipLabel: 'Segregation',
      title: 'Smart sorting keeps trucks faster',
      subtitle: 'Separate dry, wet & mixed waste every morning.',
      colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
      icon: Icons.auto_awesome,
      backgroundImage: 'assets/banner/banner2.jpg',
      subtitleFontSize: 10,
    ),
    _BannerSlide(
      chipLabel: 'Rewards',
      title: 'Earn green points every recycle',
      subtitle: 'Redeem perks from trusted partners.',
      colors: [Color(0xFF2E7D5A), Color(0xFF66BB6A)],
      icon: Icons.star_rate_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService = getIt<NotificationService>();
    _bannerPageController = PageController(viewportFraction: 0.92)
      ..addListener(_handleBannerScroll);
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bellSwing = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _bellController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bannerPageController
      ..removeListener(_handleBannerScroll)
      ..dispose();
    _bellController.dispose();
    super.dispose();
  }

  void _toggleBellAnimation(bool shouldAnimate) {
    if (shouldAnimate) {
      if (!_bellController.isAnimating) {
        _bellController.repeat(reverse: true);
      }
    } else {
      if (_bellController.isAnimating) {
        _bellController.stop();
      }
      _bellController.reset();
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
      ),
    );
  }

  void _handleBannerScroll() {
    final page = _bannerPageController.page?.round() ?? 0;
    if (page != _activeBannerIndex && mounted) {
      setState(() {
        _activeBannerIndex = page;
      });
    }
  }

  void _onBottomNavTap(_BottomNavItem item) {
    if (!mounted) return;
    setState(() {
      _activeNavItem = item;
    });
  }

  double _parseWeightValue(String value) {
    final sanitized = value.replaceAll(RegExp('[^0-9.]'), '');
    return double.tryParse(sanitized) ?? 0;
  }

  double _calculateAverageValue(_WasteStats stats) {
    final double dryValue = _parseWeightValue(stats.dry);
    final double wetValue = _parseWeightValue(stats.wet);
    final double mixedValue = _parseWeightValue(stats.mixed);
    final double totalWeight = dryValue + wetValue + mixedValue;
    final int divisor = _selectedPeriod == WastePeriod.yearly
        ? 365
        : _selectedPeriod == WastePeriod.daily
            ? 1
            : 30;
    return divisor > 0 ? totalWeight / divisor : 0;
  }

  Widget _buildCollectionStatsCard(
    BuildContext context, {
    required bool isDarkMode,
    required Color textColor,
    required Color secondaryTextColor,
    required _WasteStats stats,
  }) {
    final theme = Theme.of(context);
    final double average = _calculateAverageValue(stats);
    const List<_WasteBarData> progressItems = _collectionProgressItems;

    Widget _buildSwatch(_WasteBarData item) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            item.valueLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${average.toStringAsFixed(2)} Kg',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Average waste saving this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  children:
                      progressItems.map((item) => _buildSwatch(item)).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 120,
          height: 120,
          child: _WasteRadialBreakdown(
            items: progressItems,
            totalValue: 100,
            textColor: textColor,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    double headerHeight,
    double bannerHeight,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    Color highlightColor,
    List<Color> headerGradientColors,
    _WasteStats stats,
    List<_QuickAction> quickActions,
    String normalizedName,
    bool showUserName,
  ) {
    switch (_activeNavItem) {
      case _BottomNavItem.track:
        return _buildTrackTab(
          context,
          headerHeight,
          headerGradientColors,
          textColor,
          highlightColor,
        );
      case _BottomNavItem.profile:
        return _buildProfileTab(
          context,
          headerHeight,
          headerGradientColors,
          normalizedName,
          highlightColor,
          textColor,
          secondaryTextColor,
        );
      case _BottomNavItem.home:
        return _buildHomeTab(
          context,
          headerHeight,
          bannerHeight,
          surfaceColor,
          outlineColor,
          textColor,
          secondaryTextColor,
          highlightColor,
          headerGradientColors,
          stats,
          quickActions,
          normalizedName,
          showUserName,
        );
    }
  }

  Widget _buildHomeTab(
    BuildContext context,
    double headerHeight,
    double bannerHeight,
    Color surfaceColor,
    Color outlineColor,
    Color textColor,
    Color secondaryTextColor,
    Color highlightColor,
    List<Color> headerGradientColors,
    _WasteStats stats,
    List<_QuickAction> quickActions,
    String normalizedName,
    bool showUserName,
  ) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: headerHeight,
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
                color: Colors.black.withOpacity(
                  isDarkMode ? 0.45 : 0.15,
                ),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => context.go(AppRoutePaths.citizenProfile),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.35,
                            ),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/gif/profile.gif',
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (showUserName) ...[
                            const SizedBox(height: 6),
                            Text(
                              normalizedName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white.withValues(
                                  alpha: 0.85,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildNotificationBell(
                      context,
                      iconColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      borderColor: Colors.white.withValues(alpha: 0.25),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  surfaceColor: surfaceColor,
                  outlineColor: outlineColor,
                  isDarkMode: isDarkMode,
                  child: _buildCollectionStatsCard(
                    context,
                    isDarkMode: isDarkMode,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                    stats: stats,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _BannerPager(
          controller: _bannerPageController,
          slides: _bannerSlides,
          currentIndex: _activeBannerIndex,
          isDarkMode: isDarkMode,
          pageViewHeight: bannerHeight,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),
                _QuickActionGrid(
                  actions: quickActions,
                  isDarkMode: isDarkMode,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                  iconColor: highlightColor,
                ),
                const SizedBox(height: 72),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTab(
    BuildContext context,
    double headerHeight,
    List<Color> headerGradientColors,
    Color textColor,
    Color highlightColor,
  ) {
    final trackHeaderHeight = math.min(headerHeight * 0.6, 200.0);

    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, state) {
        final theme = Theme.of(context);

        final placeholderColor = theme.colorScheme.onSurfaceVariant;

        final vehicles =
            state is VehicleLoaded ? state.vehicles : const <VehicleModel>[];
        final vehiclesInGamma = _vehiclesInsideGamma(vehicles);

        final vehicleCount = vehiclesInGamma.length;

        final previewCenter = vehiclesInGamma.isNotEmpty
            ? LatLng(
                vehiclesInGamma.first.latitude,
                vehiclesInGamma.first.longitude,
              )
            : _gammaCenter;

        final previewZoom = vehiclesInGamma.isNotEmpty ? 15.0 : 13.2;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          if (_lastPreviewCenter != previewCenter) {
            _trackMapController.move(previewCenter, previewZoom);

            _lastPreviewCenter = previewCenter;
          }
        });

        return Column(
          children: [
            Container(
              width: double.infinity,
              height: trackHeaderHeight,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: Icon(
                        Icons.map_outlined,
                        size: 26,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Track Your Assigned Collector',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only vehicles inside ${GammaGeofenceConfig.name} are shown for your ward.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Vehicle Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTrackMapPreview(
                      context,
                      vehiclesInGamma,
                      highlightColor,
                      previewCenter,
                      previewZoom,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$vehicleCount vehicle${vehicleCount == 1 ? '' : 's'} currently inside ${GammaGeofenceConfig.name}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: placeholderColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Vehicle details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (vehiclesInGamma.isEmpty)
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No vehicles are inside ${GammaGeofenceConfig.name} right now. We will show them here as soon as one is detected.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: placeholderColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: vehiclesInGamma
                            .map(
                              (vehicle) => _buildVehicleDetailCard(
                                context,
                                vehicle,
                                highlightColor,
                                placeholderColor,
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackMapPreview(
    BuildContext context,
    List<VehicleModel> vehiclesInGamma,
    Color highlightColor,
    LatLng center,
    double zoom,
  ) {
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outline.withOpacity(0.35);
    final markers = vehiclesInGamma.map((vehicle) {
      return Marker(
        width: 40,
        height: 40,
        point: LatLng(vehicle.latitude, vehicle.longitude),
        child: Container(
          decoration: BoxDecoration(
            color: highlightColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: outlineColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _trackMapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: 11,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: GammaGeofenceConfig.polygon,
                      borderColor: highlightColor.withOpacity(0.6),
                      color: highlightColor.withOpacity(0.18),
                      borderStrokeWidth: 2.4,
                    ),
                  ],
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: FloatingActionButton.small(
                heroTag: 'track_map_maximize',
                onPressed: () =>
                    context.go(AppRoutePaths.citizenAllotedVehicleMap),
                backgroundColor: highlightColor,
                child: const Icon(Icons.open_in_full, size: 18),
              ),
            ),
            if (vehiclesInGamma.isEmpty)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.28),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Waiting for your assigned collector to enter ${GammaGeofenceConfig.name}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetailCard(
    BuildContext context,
    VehicleModel vehicle,
    Color highlightColor,
    Color placeholderColor,
  ) {
    final theme = Theme.of(context);
    final sectionColor =
        context.read<VehicleBloc>().getStatusColor(vehicle.status);
    final registration = vehicle.registrationNumber ?? 'Vehicle ${vehicle.id}';
    final driverName = vehicle.driverName ?? 'Driver info pending';
    final statusLabel = vehicle.status ?? 'Unknown';
    final updatedAt = vehicle.lastUpdated ?? 'Updated moments ago';
    final areaLabel = vehicle.address ?? '${GammaGeofenceConfig.name} ward';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: theme.brightness == Brightness.dark ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: sectionColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus, size: 20, color: sectionColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    registration,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driverName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: placeholderColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status: $statusLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: placeholderColor,
                        ),
                      ),
                      Text(
                        updatedAt,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: placeholderColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    areaLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: placeholderColor,
                      fontStyle: FontStyle.italic,
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

  Widget _buildProfileTab(
    BuildContext context,
    double headerHeight,
    List<Color> headerGradientColors,
    String normalizedName,
    Color highlightColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
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
              _buildProfileOptionTile(
                context,
                icon: Icons.description_outlined,
                label: 'Collection Details',
                onTap: () => context.go(AppRoutePaths.citizenDriverDetails),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.history,
                label: 'Collection History & Weighment',
                onTap: () => context.go(AppRoutePaths.citizenHistory),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.location_on_outlined,
                label: 'Track My Waste',
                onTap: () => _onBottomNavTap(_BottomNavItem.track),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.feedback_outlined,
                label: 'Raise Grievance (Help Desk)',
                onTap: () => context.go(AppRoutePaths.citizenGrievanceChat),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildThemeToggleTile(
                context,
                highlightColor,
                secondaryTextColor,
              ),
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
                  onTap: () {
                    authBloc.add(AuthLogoutRequested());
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color highlightColor,
  }) {
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

  Widget _buildThemeToggleTile(
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
        });
        _toggleBellAnimation(true);
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

  List<VehicleModel> _vehiclesInsideGamma(List<VehicleModel> vehicles) {
    return vehicles.where(_isInsideGammaFence).toList(growable: false);
  }

  Future<void> _openNotificationsSheet(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      _hasUnreadNotifications = false;
    });
    _toggleBellAnimation(false);

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
    _toggleBellAnimation(false);
    context.go(AppRoutePaths.citizenAllotedVehicleMap);
  }

  void _openFleetTracking() {
    if (!mounted) return;
    context.go(AppRoutePaths.citizenMap);
  }

  Widget _buildNotificationBell(
    BuildContext context, {
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final hasAlerts = _alerts.isNotEmpty;

    return AnimatedBuilder(
      animation: _bellController,
      builder: (context, child) {
        final double angle = _hasUnreadNotifications ? _bellSwing.value : 0.0;
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final baseTheme = Theme.of(context);
    final robotoTextTheme =
        GoogleFonts.robotoTextTheme(baseTheme.textTheme).copyWith(
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 26,
      ),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: baseTheme.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    final robotoPrimary =
        GoogleFonts.robotoTextTheme(baseTheme.primaryTextTheme).copyWith(
      titleLarge: baseTheme.primaryTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 26,
      ),
      titleMedium: baseTheme.primaryTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: baseTheme.primaryTextTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final theme = baseTheme.copyWith(
      textTheme: robotoTextTheme,
      primaryTextTheme: robotoPrimary,
    );
    final isDarkMode = themeMode == ThemeMode.dark;
    final colorScheme = theme.colorScheme;
    final normalizedName = widget.userName.trim();
    final bool showUserName = normalizedName.isNotEmpty &&
        normalizedName.toLowerCase() != 'citizen demo';

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
        label: 'Track Vehicles',
        icon: 'mdi:map-marker-path',
        onTap: _openFleetTracking,
      ),
      _QuickAction(
        label: 'Collection Details',
        icon: 'mdi:file-document-edit-outline',
        onTap: () => context.go(AppRoutePaths.citizenDriverDetails),
      ),
      _QuickAction(
        label: 'Collection History',
        icon: 'mdi:history',
        onTap: () => context.go(AppRoutePaths.citizenHistory),
      ),
      _QuickAction(
        label: 'Raise Grievance',
        icon: 'mdi:comment-alert-outline',
        onTap: () => context.go(AppRoutePaths.citizenGrievanceChat),
      ),
      _QuickAction(
        label: 'Rate Collector',
        icon: 'mdi:star-face',
        onTap: () => _showComingSoon(context, 'Rating feature'),
      ),
    ];

    final double screenHeight = MediaQuery.of(context).size.height;
    final double headerHeight = math.min(screenHeight * 0.34, 360);
    final double bannerHeight = math.min(headerHeight * 0.55, 190);
    final List<Color> headerGradientColors = isDarkMode
        ? const [Color(0xFF0D3A16), Color(0xFF43A047)]
        : const [Color(0xFF1B5E20), Color(0xFF66BB6A)];

    final Widget tabBody = _buildTabBody(
      context,
      headerHeight,
      bannerHeight,
      surfaceColor,
      outlineColor,
      textColor,
      secondaryTextColor,
      highlightColor,
      headerGradientColors,
      stats,
      quickActions,
      normalizedName,
      showUserName,
    );

    return BlocListener<VehicleBloc, VehicleState>(
      listenWhen: (previous, current) => current is VehicleLoaded,
      listener: (context, state) {
        if (state is VehicleLoaded) {
          _evaluateGammaGeofence(context, state);
        }
      },
      child: Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: tabBody,
          ),
          bottomNavigationBar: SafeArea(
            child: MotionTabBar(
              labels: const ['Home', 'Map', 'Profile'],
              icons: const [
                Icons.home_outlined,
                Icons.map_outlined,
                Icons.person_outline,
              ],
              initialSelectedTab: _navLabel(_activeNavItem),
              tabBarColor:
                  isDarkMode ? CitizenDashboard._darkSurface : Colors.white,
              tabSelectedColor: highlightColor,
              tabIconColor: isDarkMode ? Colors.white54 : Colors.black54,
              tabBarHeight: 64,
              tabSize: 52,
              tabIconSize: 22,
              tabIconSelectedSize: 24,
              onTabItemSelected: (value) {
                final item = value is int
                    ? _navItemFromIndex(value)
                    : value is String
                        ? _navItemFromLabel(value)
                        : null;
                if (item != null) {
                  _onBottomNavTap(item);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

enum WastePeriod { daily, monthly, yearly }

enum _BottomNavItem { home, track, profile }

const List<_BottomNavItem> _orderedNavItems = [
  _BottomNavItem.home,
  _BottomNavItem.track,
  _BottomNavItem.profile,
];

String _navLabel(_BottomNavItem item) {
  switch (item) {
    case _BottomNavItem.home:
      return 'Home';
    case _BottomNavItem.track:
      return 'Map';
    case _BottomNavItem.profile:
      return 'Profile';
  }
}

_BottomNavItem? _navItemFromLabel(String label) {
  switch (label) {
    case 'Home':
      return _BottomNavItem.home;
    case 'Map':
      return _BottomNavItem.track;
    case 'Profile':
      return _BottomNavItem.profile;
    default:
      return null;
  }
}

_BottomNavItem? _navItemFromIndex(int index) {
  if (index >= 0 && index < _orderedNavItems.length) {
    return _orderedNavItems[index];
  }
  return null;
}

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

class _WasteBarData {
  const _WasteBarData({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.color,
  });

  final String label;
  final String valueLabel;
  final double value;
  final Color color;
}

const List<_WasteBarData> _collectionProgressItems = [
  _WasteBarData(
    label: 'Wet',
    valueLabel: '70% wet',
    value: 70,
    color: Color(0xFF0D47A1),
  ),
  _WasteBarData(
    label: 'Dry',
    valueLabel: '60% dry',
    value: 60,
    color: Color(0xFFBF360C),
  ),
  _WasteBarData(
    label: 'Mixed',
    valueLabel: '60% mixed',
    value: 60,
    color: Color(0xFFB71C1C),
  ),
];

class _WasteRadialBreakdown extends StatefulWidget {
  const _WasteRadialBreakdown({
    required this.items,
    required this.totalValue,
    required this.textColor,
    required this.backgroundColor,
  });

  final List<_WasteBarData> items;
  final double totalValue;
  final Color textColor;
  final Color backgroundColor;

  @override
  State<_WasteRadialBreakdown> createState() => _WasteRadialBreakdownState();
}

class _WasteRadialBreakdownState extends State<_WasteRadialBreakdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completedOnce = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _completedOnce = true;
        }
      });
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _WasteRadialBreakdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool dataChanged = _hasChartDataChanged(
          oldWidget.items,
          widget.items,
        ) ||
        oldWidget.totalValue != widget.totalValue;

    if (dataChanged) {
      _completedOnce = false;
      _controller
        ..reset()
        ..forward();
    } else if (!_completedOnce && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _hasChartDataChanged(
    List<_WasteBarData> previous,
    List<_WasteBarData> current,
  ) {
    if (previous.length != current.length) return true;
    for (var i = 0; i < previous.length; i++) {
      final oldItem = previous[i];
      final newItem = current[i];
      if (oldItem.label != newItem.label ||
          oldItem.valueLabel != newItem.valueLabel ||
          oldItem.value != newItem.value ||
          oldItem.color.toARGB32() != newItem.color.toARGB32()) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final animationValue = Curves.easeOutCubic.transform(_controller.value);
        return AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double size = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _RadialArcPainter(
                        items: widget.items,
                        totalValue: widget.totalValue,
                        animationValue: animationValue,
                      ),
                    ),
                  ),
                  Container(
                    width: size * 0.42,
                    height: size * 0.42,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/gif/dumpster.gif',
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _RadialArcPainter extends CustomPainter {
  const _RadialArcPainter({
    required this.items,
    required this.totalValue,
    required this.animationValue,
  });

  final List<_WasteBarData> items;
  final double totalValue;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = math.min(size.width, size.height) / 2.2;
    var radius = maxRadius;
    const gap = 4.0;

    for (final data in items) {
      final strokeWidth = radius * 0.18;
      final bgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;

      final fgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            data.color.withValues(alpha: 0.8),
            data.color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bgPaint);
      final sweep =
          totalValue == 0 ? 0.0 : (data.value / totalValue).clamp(0.0, 1.0);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * sweep * animationValue,
        false,
        fgPaint,
      );

      radius -= strokeWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RadialArcPainter oldDelegate) {
    return oldDelegate.items != items ||
        oldDelegate.totalValue != totalValue ||
        oldDelegate.animationValue != animationValue;
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
    required this.iconColor,
  });

  final List<_QuickAction> actions;
  final bool isDarkMode;
  final Color surfaceColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 4;
        const spacing = 12.0;
        const runSpacing = 14.0;
        final availableWidth = constraints.maxWidth - (spacing * (columns - 1));
        final tileWidth = (availableWidth / columns)
            .clamp(0, constraints.maxWidth)
            .toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: actions.map((action) {
            return SizedBox(
              width: tileWidth,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: action.onTap,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDarkMode ? 0.18 : 0.06,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            width: 54,
                            height: 54,
                            color: isDarkMode
                                ? surfaceColor.withValues(alpha: 0.5)
                                : surfaceColor,
                            child: Center(
                              child: Iconify(
                                action.icon,
                                size: 28,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w400,
                          height: 1.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
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
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isDarkMode ? 30 : 20,
            offset: const Offset(0, 12),
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
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String icon;
  final VoidCallback onTap;
}

class _BannerSlide {
  const _BannerSlide({
    required this.chipLabel,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
    this.backgroundImage,
    this.subtitleFontSize,
  });

  final String chipLabel;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  final String? backgroundImage;
  final double? subtitleFontSize;
}

class _BannerPager extends StatelessWidget {
  const _BannerPager({
    required this.controller,
    required this.slides,
    required this.currentIndex,
    required this.isDarkMode,
    this.pageViewHeight,
  });

  final PageController controller;
  final List<_BannerSlide> slides;
  final int currentIndex;
  final bool isDarkMode;
  final double? pageViewHeight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double pageHeight = pageViewHeight ?? 180;

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: controller,
            itemCount: slides.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final slide = slides[index];
              final bool isFocused = index == currentIndex;
              final bool hasImage = slide.backgroundImage != null;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.symmetric(
                  horizontal: isFocused ? 4 : 10,
                  vertical: isFocused ? 0 : 12,
                ),
                decoration: BoxDecoration(
                  gradient: hasImage
                      ? null
                      : LinearGradient(
                          colors: slide.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  image: hasImage
                      ? DecorationImage(
                          image: AssetImage(slide.backgroundImage!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: slide.colors.last.withValues(alpha: 0.25),
                      blurRadius: isFocused ? 30 : 10,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(isFocused ? 0.35 : 0.45),
                              Colors.black.withOpacity(0.15),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              slide.chipLabel.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                letterSpacing: 0.6,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slide.title,
                                      style: textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      slide.subtitle,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                        fontSize: slide.subtitleFontSize ?? 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                slide.icon,
                                color: Colors.white,
                                size: 38,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (index) {
            final bool isActive = currentIndex == index;
            final Color activeColor =
                isDarkMode ? Colors.white : Colors.black87;
            final Color inactiveColor =
                isDarkMode ? Colors.white24 : Colors.black26;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 26 : 8,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }
}
