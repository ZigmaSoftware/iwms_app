import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:motion_tab_bar/MotionTabBar.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'alloted_vehicle_map.dart';
import '../../../core/di.dart';
import '../../../core/geofence_config.dart';
import '../../../core/utils/size_config.dart';
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

enum _WasteMetric { total, wet, dry, mixed }

class _WasteImageStatCard extends StatelessWidget {
  const _WasteImageStatCard({
    required this.assetPath,
    required this.label,
    required this.weight,
    required this.accentColor,
    required this.formatter,
    required this.isSelected,
    required this.onTap,
  });

  final String assetPath;
  final String label;
  final double weight;
  final Color accentColor;
  final NumberFormat formatter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final borderRadius = BorderRadius.circular(26);
    return SizedBox(
      height: 180,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.fastEaseInToSlowEaseOut,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? accentColor
                : accentColor.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isSelected ? 0.3 : 0.18),
              blurRadius: isSelected ? 26 : 20,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(assetPath),
                          fit: BoxFit.cover,
                          colorFilter: isSelected
                              ? ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.12),
                                  BlendMode.darken,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(26),
                        bottomRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: accentColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          child: Text(
                            '${formatter.format(weight)} kg',
                            key: ValueKey<String>(
                              '${label}_${weight.toStringAsFixed(2)}',
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WasteSummary {
  WasteSummary({
    required this.date,
    required this.totalTrip,
    required this.dryWeight,
    required this.wetWeight,
    required this.mixWeight,
    required this.totalNetWeight,
    required this.averageWeightPerTrip,
  });

  final DateTime date;
  final int totalTrip;
  final double dryWeight;
  final double wetWeight;
  final double mixWeight;
  final double totalNetWeight;
  final double averageWeightPerTrip;

  factory WasteSummary.fromJson(Map<String, dynamic> json) {
    final isoDate = json['date'] as String?;
    final parsedDate = isoDate != null
        ? DateTime.tryParse(isoDate)
        : null;
    final date = parsedDate != null
        ? DateTime(parsedDate.year, parsedDate.month, parsedDate.day)
        : DateTime.now();

    return WasteSummary(
      date: date,
      totalTrip: (json['total_trip'] as num?)?.toInt() ?? 0,
      dryWeight: (json['dry_weight'] as num?)?.toDouble() ?? 0.0,
      wetWeight: (json['wet_weight'] as num?)?.toDouble() ?? 0.0,
      mixWeight: (json['mix_weight'] as num?)?.toDouble() ?? 0.0,
      totalNetWeight: (json['total_net_weight'] as num?)?.toDouble() ?? 0.0,
      averageWeightPerTrip:
          (json['average_weight_per_trip'] as num?)?.toDouble() ?? 0.0,
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

const String _bannerFeedUrl =
    'https://raw.githubusercontent.com/ZigmaSoftware/iwms-banners/refs/heads/main/banners.json';
const String _bannerCacheKey = 'citizen_banner_feed_v1';

class _CitizenDashboardState extends State<CitizenDashboard>
    with TickerProviderStateMixin {
  static final DateFormat _trackMonthKeyFormatter = DateFormat('yyyy-MM');
  static final DateFormat _trackDateKeyFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _trackDisplayFormat =
      DateFormat('EEEE, dd MMM yyyy');
  static final DateFormat _trackShortDisplayFormat = DateFormat('d MMM');
  static final NumberFormat _trackWeightFormatter =
      NumberFormat.decimalPattern();
  static final NumberFormat _trackAverageFormatter =
      NumberFormat('#,##0.00');
  static const String _trackApiBaseUrl =
      'https://zigma.in/d2d/folders/waste_collected_summary_report/waste_collected_data_api.php';
  static const String _trackApiKey = 'ZIGMA-DELHI-WEIGHMENT-2025-SECURE';

  WastePeriod _selectedPeriod = WastePeriod.daily;
  _BottomNavItem _activeNavItem = _BottomNavItem.home;
  late final PageController _bannerPageController;
  late final AnimationController _bellController;
  late final Animation<double> _bellSwing;
  int _activeBannerIndex = 0;
  Timer? _bannerAutoSlideTimer;

  DateTime _selectedTrackDate = DateTime.now();
  String? _trackMonthKey;
  Map<String, WasteSummary> _trackSummaries = {};
  bool _isTrackDataLoading = false;
  String? _trackDataError;

  final Map<WastePeriod, _WasteStats> _wasteStats = const {
    WastePeriod.daily:
        _WasteStats(dry: '2.3 kg', wet: '1.9 kg', mixed: '0.6 kg'),
    WastePeriod.monthly:
        _WasteStats(dry: '58.0 kg', wet: '43.0 kg', mixed: '12.0 kg'),
    WastePeriod.yearly:
        _WasteStats(dry: '690 kg', wet: '510 kg', mixed: '138 kg'),
  };
  _WasteMetric _activeWasteMetric = _WasteMetric.total;

  late final NotificationService _notificationService;
  final List<_CitizenAlert> _alerts = [];
  bool _hasUnreadNotifications = false;
  bool _wasVehicleInsideGamma = false;
  late List<_BannerSlide> _bannerSlides;
  static const List<_BannerSlide> _defaultBannerSlides = [
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
    _bannerSlides = List.of(_defaultBannerSlides);
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
    _loadTrackDataForMonth(_selectedTrackDate, forceRefresh: true);
    _initializeBannerFeed();
    _restartBannerAutoSlideTimer();
  }

  @override
  void dispose() {
    _stopBannerAutoSlide();
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

  void _restartBannerAutoSlideTimer() {
    _stopBannerAutoSlide();
    if (_bannerSlides.length <= 1) {
      return;
    }
    _bannerAutoSlideTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted ||
          !_bannerPageController.hasClients ||
          _bannerSlides.length <= 1) {
        return;
      }
      final nextPage = (_activeBannerIndex + 1) % _bannerSlides.length;
      _bannerPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopBannerAutoSlide() {
    _bannerAutoSlideTimer?.cancel();
    _bannerAutoSlideTimer = null;
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final theme = Theme.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dismissOnTouchOutside: true,
      dismissOnBackKeyPress: true,
      barrierColor: Colors.black.withOpacity(0.55),
      body: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Collection QR',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Show this code to your collector for instant verification.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/qr.png',
                width: 240,
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              icon: const Icon(Icons.check),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    ).show();
  }

  void _handleBannerScroll() {
    final page = _bannerPageController.page?.round() ?? 0;
    if (page != _activeBannerIndex && mounted) {
      setState(() {
        _activeBannerIndex = page;
      });
      _restartBannerAutoSlideTimer();
    }
  }

  void _onBottomNavTap(_BottomNavItem item) {
    if (!mounted) return;
    setState(() {
      _activeNavItem = item;
    });
  }

  String _navLabel(_BottomNavItem item) {
    switch (item) {
      case _BottomNavItem.track:
        return 'Track';
      case _BottomNavItem.map:
        return 'Map';
      case _BottomNavItem.profile:
        return 'Profile';
      case _BottomNavItem.home:
      default:
        return 'Home';
    }
  }

  _BottomNavItem _navItemFromLabel(String label) {
    switch (label) {
      case 'Track':
        return _BottomNavItem.track;
      case 'Map':
        return _BottomNavItem.map;
      case 'Profile':
        return _BottomNavItem.profile;
      case 'Home':
      default:
        return _BottomNavItem.home;
    }
  }

  _BottomNavItem _navItemFromIndex(int index) {
    if (index < 0 || index >= _orderedNavItems.length) {
      return _orderedNavItems.first;
    }
    return _orderedNavItems[index];
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

  _WasteStats _statsFromSummary(WasteSummary summary) {
    String format(double value) => '${_trackWeightFormatter.format(value)} kg';
    return _WasteStats(
      dry: format(summary.dryWeight),
      wet: format(summary.wetWeight),
      mixed: format(summary.mixWeight),
    );
  }

  void _initializeBannerFeed() {
    unawaited(_loadCachedBanners());
    unawaited(_fetchRemoteBanners());
  }

  Future<void> _loadCachedBanners() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_bannerCacheKey);
      if (cached == null) return;
      final slides = _parseBannerFeed(cached);
      if (slides.isNotEmpty && mounted) {
        setState(() {
          _bannerSlides = slides;
          _activeBannerIndex = 0;
        });
        _restartBannerAutoSlideTimer();
      }
    } catch (error) {
      debugPrint('Banner cache load failed: $error');
    }
  }

  Future<void> _fetchRemoteBanners() async {
    try {
      final response = await http
          .get(Uri.parse(_bannerFeedUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        debugPrint('Banner fetch failed with status ${response.statusCode}');
        return;
      }
      final slides = _parseBannerFeed(response.body);
      if (slides.isEmpty) return;
      if (mounted) {
        setState(() {
          _bannerSlides = slides;
          _activeBannerIndex = 0;
        });
        _restartBannerAutoSlideTimer();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bannerCacheKey, response.body);
    } catch (error) {
      debugPrint('Banner fetch failed: $error');
    }
  }

  List<_BannerSlide> _parseBannerFeed(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      final Iterable<dynamic>? items;
      if (decoded is Map<String, dynamic>) {
        items = decoded['items'] as Iterable<dynamic>?;
      } else if (decoded is Iterable) {
        items = decoded;
      } else {
        return const [];
      }
      if (items == null) return const [];

      return items
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final String? title = (item['title'] as String?)?.trim();
            if (title == null || title.isEmpty) return null;

            final String subtitle = (item['subtitle'] as String?)?.trim() ?? '';
            final String chipLabel =
                (item['chipLabel'] as String?)?.trim().toUpperCase() ?? 'TIP';
            final List<Color> colors = _parseColorList(item['colors']) ??
                const [Color(0xFF1B5E20), Color(0xFF43A047)];
            final IconData icon =
                _iconFromName(item['icon'] as String?) ?? Icons.eco_outlined;
            final String? imageUrl = (item['imageUrl'] as String?)?.trim();
            final double? subtitleFontSize =
                (item['subtitleFontSize'] as num?)?.toDouble();

            return _BannerSlide(
              chipLabel: chipLabel.isEmpty ? 'TIP' : chipLabel,
              title: title,
              subtitle: subtitle,
              colors: colors,
              icon: icon,
              backgroundImage: imageUrl,
              subtitleFontSize: subtitleFontSize,
              isNetworkImage: imageUrl != null && imageUrl.startsWith('http'),
            );
          })
          .whereType<_BannerSlide>()
          .toList();
    } catch (error) {
      debugPrint('Banner parse failed: $error');
      return const [];
    }
  }

  List<Color>? _parseColorList(dynamic value) {
    if (value is List) {
      final colors = value
          .map((entry) => _parseColorString(entry as String?))
          .whereType<Color>()
          .toList();
      if (colors.length >= 2) return colors;
      if (colors.length == 1) {
        final base = colors.first;
        return [base, base.withValues(alpha: 0.8)];
      }
    } else if (value is String) {
      final color = _parseColorString(value);
      if (color != null) {
        return [color, color.withValues(alpha: 0.8)];
      }
    }
    return null;
  }

  Color? _parseColorString(String? raw) {
    if (raw == null) return null;
    String value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('#')) value = value.substring(1);
    if (value.toLowerCase().startsWith('0x')) {
      value = value.substring(2);
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) return null;
    final int? parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  IconData? _iconFromName(String? name) {
    if (name == null) return null;
    switch (name.toLowerCase()) {
      case 'support':
      case 'help':
        return Icons.support_agent;
      case 'map':
      case 'track':
        return Icons.map_outlined;
      case 'star':
      case 'reward':
        return Icons.star_rate_outlined;
      case 'segregation':
      case 'tips':
        return Icons.auto_awesome;
      case 'clean':
      case 'eco':
        return Icons.eco_outlined;
      default:
        return null;
    }
  }

  Widget _buildCollectionStatsCard(
    BuildContext context, {
    required bool isDarkMode,
    required Color textColor,
    required Color secondaryTextColor,
    required _WasteStats stats,
    WasteSummary? summary,
  }) {
    final theme = Theme.of(context);
    final double average = _calculateAverageValue(stats);
    final WasteSummary? liveSummary = summary;
    final bool hasLiveSummary = liveSummary != null;
    final double dryValue = _parseWeightValue(stats.dry);
    final double wetValue = _parseWeightValue(stats.wet);
    final double mixedValue = _parseWeightValue(stats.mixed);
    final double computedTotal = dryValue + wetValue + mixedValue;
    final double? liveTotal = liveSummary?.totalNetWeight;
    final double primaryValue = liveTotal ?? average;
    final String primaryLabel = hasLiveSummary
        ? 'Total waste collected'
        : 'Average waste saving this month';
    final List<_WasteBarData> progressItems;
    if (liveSummary != null) {
      progressItems = [
        _WasteBarData(
          label: 'Wet',
          value: wetValue,
          valueLabel:
              'Wet ${_trackWeightFormatter.format(liveSummary.wetWeight)} kg',
          color: const Color(0xFF1976D2),
        ),
        _WasteBarData(
          label: 'Dry',
          value: dryValue,
          valueLabel:
              'Dry ${_trackWeightFormatter.format(liveSummary.dryWeight)} kg',
          color: const Color(0xFF2E7D32),
        ),
        _WasteBarData(
          label: 'Mixed',
          value: mixedValue,
          valueLabel: 'Mixed ${_trackWeightFormatter.format(liveSummary.mixWeight)} kg',
          color: const Color(0xFFF57F17),
        ),
      ];
    } else {
      progressItems = _collectionProgressItems;
    }
    final double chartTotal = hasLiveSummary ? computedTotal : 100;

    Widget buildSwatch(_WasteBarData item) {
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

    final responsive = SizeConfig.of(context);
    final double radialSize =
        responsive.safeWidthPercent(0.22).clamp(90.0, 130.0);
    final double rowGap = responsive.safeWidthPercent(0.028).clamp(8.0, 18.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_trackWeightFormatter.format(primaryValue)} Kg',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                primaryLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  alignment: WrapAlignment.start,
                  children:
                      progressItems.map((item) => buildSwatch(item)).toList(),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: rowGap),
        SizedBox(
          width: radialSize,
          height: radialSize,
          child: _WasteRadialBreakdown(
            items: progressItems,
            totalValue: chartTotal,
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
    List<Color> sectionHeaderGradientColors,
    _WasteStats stats,
    WasteSummary? summary,
    List<_QuickAction> quickActions,
    String normalizedName,
    bool showUserName,
  ) {
    switch (_activeNavItem) {
      case _BottomNavItem.track:
        return _buildTrackTab(
          context,
          headerHeight,
          sectionHeaderGradientColors,
          textColor,
          highlightColor,
        );
      case _BottomNavItem.map:
        return const CitizenAllotedVehicleMapScreen();
      case _BottomNavItem.profile:
        return _buildProfileTab(
          context,
          headerHeight,
          sectionHeaderGradientColors,
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
          summary,
          quickActions,
          normalizedName,
          showUserName,
        );
    }
  }

  WasteSummary? get _currentTrackSummary {
    final key = _trackDateKeyFormatter.format(
      DateTime(
        _selectedTrackDate.year,
        _selectedTrackDate.month,
        _selectedTrackDate.day,
      ),
    );
    return _trackSummaries[key];
  }

  Future<void> _loadTrackDataForMonth(
    DateTime referenceDate, {
    bool forceRefresh = false,
  }) async {
    final DateTime monthStart =
        DateTime(referenceDate.year, referenceDate.month, 1);
    final String monthKey = _trackMonthKeyFormatter.format(monthStart);
    if (!forceRefresh &&
        _trackMonthKey == monthKey &&
        _trackSummaries.isNotEmpty) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _isTrackDataLoading = true;
      _trackDataError = null;
    });

    try {
      final uri = Uri.parse(_trackApiBaseUrl).replace(
        queryParameters: {
          'from_date': _trackDateKeyFormatter.format(monthStart),
          'key': _trackApiKey,
        },
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch live data');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List<dynamic>?;
      final Map<String, WasteSummary> freshData = {};
      if (dataList != null) {
        for (final raw in dataList) {
          if (raw is Map<String, dynamic>) {
            final summary = WasteSummary.fromJson(raw);
            final String key = _trackDateKeyFormatter.format(summary.date);
            freshData[key] = summary;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _trackSummaries = freshData;
        _trackMonthKey = monthKey;
        _isTrackDataLoading = false;
        _trackDataError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTrackDataLoading = false;
        _trackDataError = 'Unable to load live data. Pull down to retry.';
      });
    }
  }

  Future<void> _pickTrackDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTrackDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Pick a date to view collection',
      builder: (context, child) {
        final Widget picker = child ?? const SizedBox.shrink();
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  secondary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: picker,
        );
      },
    );
    if (picked == null || !mounted) {
      return;
    }
    final DateTime normalized = DateTime(picked.year, picked.month, picked.day);
    final String newMonthKey =
        _trackMonthKeyFormatter.format(DateTime(normalized.year, normalized.month, 1));
    if (_trackMonthKey != newMonthKey || _trackSummaries.isEmpty) {
      await _loadTrackDataForMonth(normalized);
    }
    if (!mounted) return;
    setState(() {
      _selectedTrackDate = normalized;
    });
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
    WasteSummary? summary,
    List<_QuickAction> quickActions,
    String normalizedName,
    bool showUserName,
  ) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final responsive = SizeConfig.of(context);
    final Color headerPrimaryTextColor =
        isDarkMode ? Colors.white : Colors.black87;
    final Color headerSecondaryTextColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.85) : Colors.black54;
    final Color avatarBorderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.15);
    final Color headerIconColor =
        isDarkMode ? Colors.white : Colors.black87;
    final Color headerIconBackground = isDarkMode
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.05);
    final Color headerIconBorder = isDarkMode
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.1);
    final double horizontalPadding =
        responsive.safeWidthPercent(0.056).clamp(14.0, 30.0);
    final double verticalPadding =
        responsive.safeHeightPercent(0.02).clamp(12.0, 24.0);
    final double avatarGap =
        responsive.safeWidthPercent(0.035).clamp(10.0, 26.0);
    final double headerSectionSpacing =
        responsive.safeHeightPercent(0.02).clamp(12.0, 24.0);
    final double bannerSpacing =
        responsive.safeHeightPercent(0.02).clamp(12.0, 20.0);
    final double quickActionSpacing =
        responsive.safeHeightPercent(0.018).clamp(10.0, 18.0);
    final double contentBottomPadding =
        responsive.safeHeightPercent(0.04).clamp(20.0, 48.0);
    final double contentHorizontalPadding =
        responsive.safeWidthPercent(0.05).clamp(14.0, 28.0);
    final double trailingSpacing =
        responsive.safeHeightPercent(0.03).clamp(18.0, 40.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: headerHeight,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.push(AppRoutePaths.citizenProfile),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarBorderColor,
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform.scale(
                          scale: 1.12,
                          child: Image.asset(
                            'assets/gif/profile.gif',
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: avatarGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Home',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: headerPrimaryTextColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          if (showUserName) ...[
                            const SizedBox(height: 2),
                            Text(
                              normalizedName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: headerSecondaryTextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildNotificationBell(
                      context,
                      iconColor: headerIconColor,
                      backgroundColor: headerIconBackground,
                      borderColor: headerIconBorder,
                    ),
                  ],
                ),
                SizedBox(height: headerSectionSpacing * 0.4),
              ],
            ),
          ),
        ),
        SizedBox(height: headerSectionSpacing * 0.25),
        _BannerPager(
          controller: _bannerPageController,
          slides: _bannerSlides,
          currentIndex: _activeBannerIndex,
          isDarkMode: isDarkMode,
          pageViewHeight: bannerHeight,
        ),
        SizedBox(height: headerSectionSpacing * 0.5),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: _SectionCard(
            surfaceColor: surfaceColor,
            outlineColor: outlineColor,
            isDarkMode: isDarkMode,
            child: _buildCollectionStatsCard(
              context,
              isDarkMode: isDarkMode,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              stats: stats,
              summary: summary,
            ),
          ),
        ),
        SizedBox(height: bannerSpacing),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              contentHorizontalPadding,
              0,
              contentHorizontalPadding,
              contentBottomPadding,
            ),
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
                SizedBox(height: quickActionSpacing),
                _QuickActionGrid(
                  actions: quickActions,
                  isDarkMode: isDarkMode,
                  surfaceColor: surfaceColor,
                  textColor: textColor,
                ),
                SizedBox(height: trailingSpacing),
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
    final theme = Theme.of(context);
    final responsive = SizeConfig.of(context);
    final double horizontalPadding =
        responsive.safeWidthPercent(0.05).clamp(16.0, 28.0);
    final double topSpacing =
        responsive.safeHeightPercent(0.03).clamp(16.0, 30.0);
    final double bottomPadding =
        responsive.safeHeightPercent(0.12).clamp(70.0, 120.0);
    final double summarySpacing =
        responsive.safeHeightPercent(0.02).clamp(16.0, 24.0);
    final WasteSummary? summary = _currentTrackSummary;

    return RefreshIndicator(
      onRefresh: () =>
          _loadTrackDataForMonth(_selectedTrackDate, forceRefresh: true),
      color: highlightColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topSpacing,
          horizontalPadding,
          bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrackHeader(context, highlightColor, textColor),
            SizedBox(height: summarySpacing),
            _buildTrackSummarySection(
              context: context,
              summary: summary,
              highlightColor: highlightColor,
              textColor: textColor,
            ),
            SizedBox(height: summarySpacing * 1.2),
            Text(
              'Data refreshed for ${_trackDisplayFormat.format(_selectedTrackDate)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackSummarySection({
    required BuildContext context,
    required WasteSummary? summary,
    required Color highlightColor,
    required Color textColor,
  }) {
    if (_isTrackDataLoading) {
      return _buildTrackStatusCard(
        context: context,
        message: 'Pulling live collection figures...',
        accentColor: highlightColor,
        showLoading: true,
      );
    }

    if (_trackDataError != null) {
      return _buildTrackStatusCard(
        context: context,
        message: _trackDataError!,
        accentColor: highlightColor,
        actionLabel: 'Retry now',
        onAction: () =>
            _loadTrackDataForMonth(_selectedTrackDate, forceRefresh: true),
      );
    }

    if (summary == null) {
      return _buildTrackStatusCard(
        context: context,
        message: 'No collection data is available for this date yet.',
        accentColor: highlightColor,
        actionLabel: 'Choose another date',
        onAction: () => _pickTrackDate(context),
      );
    }

    final theme = Theme.of(context);
    final cards = <({
      String asset,
      String label,
      double weight,
      Color color,
      _WasteMetric metric,
    })>[
      (
        asset: 'assets/cards/wetwaste.png',
        label: 'Wet Waste',
        weight: summary.wetWeight,
        color: const Color(0xFF1976D2),
        metric: _WasteMetric.wet
      ),
      (
        asset: 'assets/cards/drywaste.png',
        label: 'Dry Waste',
        weight: summary.dryWeight,
        color: const Color(0xFF2E7D32),
        metric: _WasteMetric.dry
      ),
      (
        asset: 'assets/cards/mixedwaste.png',
        label: 'Mixed Waste',
        weight: summary.mixWeight,
        color: const Color(0xFFF57F17),
        metric: _WasteMetric.mixed
      ),
    ];
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSummaryCard(context, summary, highlightColor, textColor),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 12;
              final children = <Widget>[];
              for (var i = 0; i < cards.length; i++) {
                final data = cards[i];
                children.add(
                  Expanded(
                    child: _WasteImageStatCard(
                      assetPath: data.asset,
                      label: data.label,
                      weight: data.weight,
                      accentColor: data.color,
                      formatter: _trackWeightFormatter,
                      isSelected: _activeWasteMetric == data.metric,
                      onTap: () => _handleMetricSelection(data.metric),
                    ),
                  ),
                );
                if (i != cards.length - 1) {
                  children.add(const SizedBox(width: gap));
                }
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            },
          ),
          const SizedBox(height: 18),
          _buildMetricDetailCard(
            context: context,
            summary: summary,
            highlightColor: highlightColor,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  void _handleMetricSelection(_WasteMetric metric) {
    if (_activeWasteMetric == metric) {
      setState(() => _activeWasteMetric = _WasteMetric.total);
    } else {
      setState(() => _activeWasteMetric = metric);
    }
  }

  double _metricWeightForSummary(WasteSummary summary, _WasteMetric metric) {
    switch (metric) {
      case _WasteMetric.wet:
        return summary.wetWeight;
      case _WasteMetric.dry:
        return summary.dryWeight;
      case _WasteMetric.mixed:
        return summary.mixWeight;
      case _WasteMetric.total:
        return summary.totalNetWeight;
    }
  }

  String _metricHeaderText(_WasteMetric metric) {
    switch (metric) {
      case _WasteMetric.wet:
        return 'Wet waste collected';
      case _WasteMetric.dry:
        return 'Dry waste collected';
      case _WasteMetric.mixed:
        return 'Mixed waste collected';
      case _WasteMetric.total:
        return 'Total waste collected';
    }
  }

  Color _metricAccentColor(_WasteMetric metric, Color highlightColor) {
    switch (metric) {
      case _WasteMetric.wet:
        return const Color(0xFF1976D2);
      case _WasteMetric.dry:
        return const Color(0xFF2E7D32);
      case _WasteMetric.mixed:
        return const Color(0xFFF57F17);
      case _WasteMetric.total:
        return highlightColor;
    }
  }

  Widget _buildMetricDetailCard({
    required BuildContext context,
    required WasteSummary summary,
    required Color highlightColor,
    required Color textColor,
  }) {
    final theme = Theme.of(context);
    final metric = _activeWasteMetric;
    final double weight = _metricWeightForSummary(summary, metric);
    final Color accent = _metricAccentColor(metric, highlightColor);
    final String weightLabel =
        '${_trackWeightFormatter.format(weight)} kg';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.fastEaseInToSlowEaseOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Text(
              _metricHeaderText(metric),
              key: ValueKey<String>('metric-header-${metric.name}'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInBack,
            child: Text(
              weightLabel,
              key: ValueKey<String>('metric-weight-$weightLabel'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric == _WasteMetric.total
                ? 'Tap a card above to view detailed breakdown.'
                : 'Tap again to switch back to total waste.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSummaryCard(
    BuildContext context,
    WasteSummary summary,
    Color highlightColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            highlightColor.withOpacity(0.96),
            highlightColor.withOpacity(0.68),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: highlightColor.withOpacity(0.32),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total trips',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary.totalTrip.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Avg per trip',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_trackAverageFormatter.format(summary.averageWeightPerTrip)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Total weight',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_trackWeightFormatter.format(summary.totalNetWeight)} kg',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Live data for ${_trackDisplayFormat.format(summary.date)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStatusCard({
    required BuildContext context,
    required String message,
    required Color accentColor,
    bool showLoading = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLoading)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          if (actionLabel != null && onAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackHeader(
    BuildContext context,
    Color highlightColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Your Waste',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live weighment figures from the city for the selected date.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _pickTrackDate(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: highlightColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: highlightColor.withOpacity(0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month,
                      size: 20, color: highlightColor),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: highlightColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                        child: Text(
                          _trackShortDisplayFormat.format(_selectedTrackDate),
                          key: ValueKey(_selectedTrackDate.day),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: highlightColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                onTap: () => context.push(AppRoutePaths.citizenDriverDetails),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.history,
                label: 'Collection History & Weighment',
                onTap: () => context.push(AppRoutePaths.citizenHistory),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.location_on_outlined,
                label: 'Track My Waste',
                onTap: () => _onBottomNavTap(_BottomNavItem.map),
                textColor: textColor,
                highlightColor: highlightColor,
              ),
              _buildProfileOptionTile(
                context,
                icon: Icons.feedback_outlined,
                label: 'Raise Grievance (Help Desk)',
                onTap: () => context.push(AppRoutePaths.citizenGrievanceChat),
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

      // Removed snackbar to keep notification subtle
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
    context.push(AppRoutePaths.citizenAllotedVehicleMap);
  }

  void _openFleetTracking() {
    if (!mounted) return;
    context.push(AppRoutePaths.citizenMap);
  }


  Widget _buildNotificationBell(
    BuildContext context, {
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final hasAlerts = _alerts.isNotEmpty;
    const double bellButtonSize = 33.6;
    const double bellIconSize = 18.0;

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
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: bellButtonSize,
                height: bellButtonSize,
              ),
              iconSize: bellIconSize,
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
        : const Color.fromRGBO(235, 248, 239, 1);
    final surfaceColor =
        isDarkMode ? CitizenDashboard._darkSurface : Colors.white;
    final outlineColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final highlightColor =
        isDarkMode ? colorScheme.secondary : colorScheme.primary;

    final WasteSummary? activeSummary = _currentTrackSummary;
    final stats = activeSummary != null
        ? _statsFromSummary(activeSummary)
        : _wasteStats[_selectedPeriod]!;

    final quickActions = [
      _QuickAction(
        label: 'Track Vehicles',
        assetPath: 'assets/icons/track_vehicles.png',
        onTap: _openFleetTracking,
      ),
      _QuickAction(
        label: 'Collection Details',
        assetPath: 'assets/icons/collection_details.png',
        onTap: () => context.push(AppRoutePaths.citizenDriverDetails),
      ),
      _QuickAction(
        label: 'Collection History',
        assetPath: 'assets/icons/collectionhistory.png',
        onTap: () => context.push(AppRoutePaths.citizenHistory),
      ),
      _QuickAction(
        label: 'Raise Grievance',
        assetPath: 'assets/icons/raise_grievance.png',
        onTap: () => context.push(AppRoutePaths.citizenGrievanceChat),
      ),
      _QuickAction(
        label: 'Rate Collector',
        assetPath: 'assets/icons/rate_collector.png',
        onTap: () => _showComingSoon(context, 'Rating feature'),
      ),
      _QuickAction(
        label: 'QR',
        assetPath: 'assets/icons/qr.png',
        onTap: () => _showQrDialog(context),
      ),
      _QuickAction(
        label: 'Upcoming Collection',
        assetPath: 'assets/icons/upcoming_collection.png',
        onTap: () => _showComingSoon(context, 'Upcoming collection schedule'),
      ),
    ];

    final responsive = SizeConfig.of(context);
    final double headerHeight =
        math.min(responsive.safeHeightPercent(0.36), 360);
    final double bannerHeight = math.min(
      headerHeight * 0.55,
      math.min(responsive.safeHeightPercent(0.24), 190),
    );
    final List<Color> headerGradientColors = isDarkMode
        ? const [Color.fromARGB(235, 248, 239, 239), Color.fromARGB(235, 248, 239, 239)]
        : const [Color.fromARGB(235, 248, 239, 239), Color.fromARGB(235, 248, 239, 239)];
    final List<Color> sectionHeaderGradientColors = isDarkMode
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
      sectionHeaderGradientColors,
      stats,
      activeSummary,
      quickActions,
      normalizedName,
      showUserName,
    );
    final bool isMapTab = _activeNavItem == _BottomNavItem.map;

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
          body: Stack(
            children: [
              Positioned.fill(
                child: isMapTab ? tabBody : SafeArea(child: tabBody),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: MotionTabBar(
              labels: const ['Home', 'Track', 'Map', 'Profile'],
              icons: const [
                Icons.home_outlined,
                Icons.delete_outline,
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

enum _BottomNavItem { home, track, map, profile }

const List<_BottomNavItem> _orderedNavItems = [
  _BottomNavItem.home,
  _BottomNavItem.track,
  _BottomNavItem.map,
  _BottomNavItem.profile,
];

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
    required this.value,
    required this.valueLabel,
    required this.color,
  });

  final String label;
  final double value;
  final String valueLabel;
  final Color color;
}

const List<_WasteBarData> _collectionProgressItems = [
  _WasteBarData(
    label: 'Wet',
    value: 40,
    valueLabel: 'Wet 40%',
    color: Color(0xFF1976D2),
  ),
  _WasteBarData(
    label: 'Dry',
    value: 32,
    valueLabel: 'Dry 32%',
    color: Color(0xFF2E7D32),
  ),
  _WasteBarData(
    label: 'Mixed',
    value: 28,
    valueLabel: 'Mixed 28%',
    color: Color(0xFFF57F17),
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
          oldItem.color.value != newItem.color.value) {
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
                    padding: const EdgeInsets.all(6),
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
  });

  final List<_QuickAction> actions;
  final bool isDarkMode;
  final Color surfaceColor;
  final Color textColor;

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
                            child: Image.asset(
                              action.assetPath,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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

class _BannerSlide {
  const _BannerSlide({
    required this.chipLabel,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.icon,
    this.backgroundImage,
    this.subtitleFontSize,
    this.isNetworkImage = false,
  });

  final String chipLabel;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;
  final String? backgroundImage;
  final double? subtitleFontSize;
  final bool isNetworkImage;
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
    final responsive = SizeConfig.of(context);
    final double pageHeight = pageViewHeight ?? 180;
    final double bannerHorizontalPadding =
        responsive.safeWidthPercent(0.045).clamp(12.0, 28.0);
    final double bannerVerticalPadding =
        responsive.safeHeightPercent(0.02).clamp(10.0, 22.0);
    final double chipGap =
        responsive.safeHeightPercent(0.018).clamp(10.0, 22.0);
    final double textGap = responsive.safeHeightPercent(0.01).clamp(6.0, 16.0);
    final double iconGap = responsive.safeWidthPercent(0.03).clamp(10.0, 26.0);
    final double indicatorSpacing =
        responsive.safeWidthPercent(0.011).clamp(4.0, 10.0);
    final double indicatorHeight =
        responsive.safeHeightPercent(0.012).clamp(6.0, 12.0);
    final double indicatorActiveWidth =
        responsive.safeWidthPercent(0.08).clamp(20.0, 32.0);
    final double indicatorInactiveWidth =
        responsive.safeWidthPercent(0.03).clamp(8.0, 14.0);
    final double indicatorRowGap = indicatorSpacing * 1.5;

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
              final ImageProvider? backgroundProvider =
                  slide.backgroundImage == null
                      ? null
                      : slide.isNetworkImage
                          ? NetworkImage(slide.backgroundImage!)
                          : AssetImage(slide.backgroundImage!) as ImageProvider;
              final bool hasImage = backgroundProvider != null;
              const animationDuration = Duration(milliseconds: 260);
              return AnimatedSlide(
                duration: animationDuration,
                curve: Curves.easeOutCubic,
                offset: isFocused ? Offset.zero : const Offset(0, 0.03),
                child: AnimatedScale(
                  duration: animationDuration,
                  curve: Curves.easeOutCubic,
                  scale: isFocused ? 1 : 0.94,
                  child: AnimatedOpacity(
                    duration: animationDuration,
                    curve: Curves.easeOutCubic,
                    opacity: isFocused ? 1 : 0.8,
                    child: AnimatedContainer(
                      duration: animationDuration,
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                colors: slide.colors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        image: backgroundProvider == null
                            ? null
                            : DecorationImage(
                                image: backgroundProvider,
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.35),
                                  BlendMode.darken,
                                ),
                              ),
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
                                    Colors.black
                                        .withOpacity(isFocused ? 0.35 : 0.45),
                                    Colors.black.withOpacity(0.15),
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: bannerHorizontalPadding,
                              vertical: bannerVerticalPadding,
                            ),
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
                                SizedBox(height: chipGap),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AutoSizeText(
                                            slide.title,
                                            style:
                                                textTheme.titleLarge?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            maxLines: 2,
                                            minFontSize: 18,
                                            maxFontSize: 28,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: textGap),
                                          AutoSizeText(
                                            slide.subtitle,
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color: Colors.white
                                                  .withValues(alpha: 0.85),
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  slide.subtitleFontSize ?? 12,
                                            ),
                                            maxLines: 2,
                                            minFontSize: 10,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: iconGap),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: indicatorRowGap),
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
              margin: EdgeInsets.symmetric(horizontal: indicatorSpacing),
              height: indicatorHeight,
              width: isActive ? indicatorActiveWidth : indicatorInactiveWidth,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(indicatorHeight * 2),
              ),
            );
          }),
        ),
      ],
    );
  }
}

