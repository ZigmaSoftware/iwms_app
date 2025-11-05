import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/di.dart';
import '../../../shared/models/collection_history.dart';
import '../../../shared/services/collection_history_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CollectionHistoryService _historyService;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _historyService = getIt<CollectionHistoryService>();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: Colors.white,
              onSurface: kTextColor,
            ),
           dialogTheme: DialogThemeData(
  backgroundColor: Colors.white,
),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'dry':
        return Colors.blue;
      case 'wet':
        return Colors.green;
      case 'mixed':
        return Colors.deepOrange;
      default:
        return kPrimaryColor;
    }
  }

  List<CollectionHistoryEntry> _entriesForSelectedDate(
    List<CollectionHistoryEntry> entries,
  ) {
    return entries.where((entry) {
      final date = entry.collectedAt;
      return date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        "//";
    final formattedHeader = "/";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection History'),
        backgroundColor: kPrimaryColor,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<CollectionHistoryEntry>>(
        valueListenable: _historyService.entriesNotifier,
        builder: (context, entries, _) {
          final filtered = _entriesForSelectedDate(entries);
          final totalWeightForDate =
              filtered.fold<double>(0, (sum, entry) => sum + entry.totalWeight);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 28, color: kPrimaryColor),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: kPlaceholderColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Viewing: ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: kTextColor,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios,
                              size: 18, color: kPlaceholderColor),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Collection Log for ',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kTextColor,
                      ),
                ),
                const Divider(height: 20),
                if (totalWeightForDate > 0)
                  Card(
                    color: kPrimaryColor.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total Weight Collected: '
                        " kg",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Center(
                      child: Column(
                        children: const [
                          Icon(Icons.inbox_outlined,
                              size: 64, color: kPlaceholderColor),
                          SizedBox(height: 12),
                          Text(
                            'No collection data for this date yet.',
                            style: TextStyle(
                                fontSize: 16, color: kPlaceholderColor),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map(_buildEntryCard),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(CollectionHistoryEntry entry) {
    final sectionsWithData = entry.sections
        .where((section) =>
            (section.weight?.isNotEmpty ?? false) ||
            (section.imagePath?.isNotEmpty ?? false) ||
            (section.imageBase64?.isNotEmpty ?? false))
        .toList();

    final timeLabel = DateFormat('h:mm a').format(entry.collectedAt);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Collected at ',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer ID: ',
              style: const TextStyle(color: kPlaceholderColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Total Weight:  kg',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor,
              ),
            ),
            const Divider(height: 24),
            if (sectionsWithData.isEmpty)
              const Text(
                'No detailed data captured for this visit.',
                style: TextStyle(color: kPlaceholderColor),
              )
            else
              for (final section in sectionsWithData)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildSectionRow(section),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionRow(CollectionHistorySection section) {
    final color = _colorForType(section.normalizedType);
    final rawWeight = section.weight?.trim() ?? '';
    final hasWeight = rawWeight.isNotEmpty;
    final weightDisplay = hasWeight
        ? (RegExp('[a-zA-Z]').hasMatch(rawWeight) ? rawWeight : '$rawWeight kg')
        : 'Not recorded';
    final typeLabel =
        '${section.type[0].toUpperCase()}${section.type.substring(1)} Waste';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: _buildSectionImage(section),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  weightDisplay,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: ((section.imagePath != null &&
                              section.imagePath!.isNotEmpty) ||
                          (section.imageBase64 != null &&
                              section.imageBase64!.isNotEmpty))
                      ? () => _viewProof(context, section)
                      : null,
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  label: const Text('View Proof'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionImage(CollectionHistorySection section) {
    if (section.imageBase64 != null && section.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(section.imageBase64!);
        return Image.memory(
          bytes,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        );
      } catch (_) {
        // ignore decode errors and fall back to path
      }
    }

    if (section.imagePath == null || section.imagePath!.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        color: kPlaceholderColor.withOpacity(0.2),
        child: const Center(
          child: Icon(Icons.image, color: Colors.grey),
        ),
      );
    }
    final file = File(section.imagePath!);
    if (!file.existsSync()) {
      return Container(
        width: 100,
        height: 100,
        color: kPlaceholderColor.withOpacity(0.2),
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Image.file(
      file,
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  void _viewProof(
    BuildContext context,
    CollectionHistorySection section,
  ) {
    if ((section.imageBase64 == null || section.imageBase64!.isEmpty) &&
        (section.imagePath == null || section.imagePath!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No proof image available for this entry.'),
        ),
      );
      return;
    }

    Widget? imageWidget;
    if (section.imageBase64 != null && section.imageBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(section.imageBase64!);
        imageWidget = Image.memory(bytes, fit: BoxFit.contain);
      } catch (_) {
        imageWidget = null;
      }
    }

    if (imageWidget == null &&
        section.imagePath != null &&
        section.imagePath!.isNotEmpty) {
      final file = File(section.imagePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(file, fit: BoxFit.contain);
      }
    }

    if (imageWidget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proof image could not be found.'),
        ),
      );
      return;
    }

    final proofWidget = imageWidget;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: proofWidget),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

