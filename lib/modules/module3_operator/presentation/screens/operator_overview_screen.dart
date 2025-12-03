import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:iwms_citizen_app/core/di.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/theme/operator_theme.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_cards.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/widgets/operator_history_tabs.dart';
import 'package:iwms_citizen_app/shared/models/collection_history.dart';
import 'package:iwms_citizen_app/shared/services/collection_history_service.dart';

class OperatorOverviewScreen extends StatelessWidget {
  const OperatorOverviewScreen({super.key});

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  double _parseSectionWeight(String? raw) {
    if (raw == null) return 0;
    final normalized = raw.replaceAll(RegExp('[^0-9.]'), '');
    if (normalized.isEmpty) return 0;
    return double.tryParse(normalized) ?? 0;
  }

  List<OperatorHistoryEntry> _mapEntries(
    List<CollectionHistoryEntry> entries,
  ) {
    final formatter = DateFormat('hh:mm a');
    return entries.map((entry) {
      double wet = 0;
      double dry = 0;
      double other = 0;

      for (final section in entry.sections) {
        final weight = _parseSectionWeight(section.weight);
        final type = section.normalizedType;
        if (type.contains('wet')) {
          wet += weight;
        } else if (type.contains('dry')) {
          dry += weight;
        } else {
          other += weight;
        }
      }

      final title =
          entry.customerName.isNotEmpty ? entry.customerName : 'Customer';
      final subtitle = entry.customerId.isNotEmpty
          ? 'ID ${entry.customerId}'
          : entry.customerName;

      return OperatorHistoryEntry(
        routeName: title,
        location: subtitle,
        timestamp: formatter.format(entry.collectedAt),
        totalKg: entry.totalWeight,
        wetKg: wet,
        dryKg: dry,
        otherKg: other,
      );
    }).toList();
  }

  List<OperatorHistoryTabData> _buildTabs(List<OperatorHistoryEntry> entries) {
    final tabs = <OperatorHistoryTabData>[
      OperatorHistoryTabData(label: 'All', entries: entries),
      OperatorHistoryTabData(
        label: 'Wet',
        entries: entries.where((e) => e.wetKg > 0).toList(),
      ),
      OperatorHistoryTabData(
        label: 'Dry',
        entries: entries.where((e) => e.dryKg > 0).toList(),
      ),
    ];

    final mixed = entries.where((e) => e.otherKg > 0).toList();
    if (mixed.isNotEmpty) {
      tabs.add(OperatorHistoryTabData(label: 'Mixed', entries: mixed));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final historyService = getIt<CollectionHistoryService>();

    return ValueListenableBuilder<List<CollectionHistoryEntry>>(
      valueListenable: historyService.entriesNotifier,
      builder: (context, entries, _) {
        final today = entries
            .where((entry) => _isSameDay(entry.collectedAt, DateTime.now()))
            .toList()
          ..sort((a, b) => b.collectedAt.compareTo(a.collectedAt));

        if (today.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Collection overview",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: OperatorTheme.strongText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: OperatorTheme.cardRadius,
                    boxShadow: OperatorTheme.softShadow,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    "There are no collections for today.",
                    style: TextStyle(color: OperatorTheme.mutedText),
                  ),
                ),
              ),
            ],
          );
        }

        final mapped = _mapEntries(today);
        final wetTotal =
            mapped.fold<double>(0, (sum, item) => sum + item.wetKg);
        final dryTotal =
            mapped.fold<double>(0, (sum, item) => sum + item.dryKg);
        final otherTotal =
            mapped.fold<double>(0, (sum, item) => sum + item.otherKg);
        final tabs = _buildTabs(mapped);

        final summaryMetrics = <Widget>[
          Expanded(
            child: OperatorQuickStat(
              label: "Wet collected",
              value: '${wetTotal.toStringAsFixed(1)} kg',
              icon: Icons.water_drop,
              emphasis: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OperatorQuickStat(
              label: "Dry collected",
              value: '${dryTotal.toStringAsFixed(1)} kg',
              icon: Icons.layers_outlined,
            ),
          ),
        ];

        if (otherTotal > 0) {
          summaryMetrics.add(const SizedBox(width: 12));
          summaryMetrics.add(
            Expanded(
              child: OperatorQuickStat(
                label: "Mixed / other",
                value: '${otherTotal.toStringAsFixed(1)} kg',
                icon: Icons.inventory_rounded,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Collection overview",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: OperatorTheme.strongText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            OperatorInfoCard(
              title: "Today's summary",
              subtitle:
                  "${mapped.length} ${mapped.length == 1 ? 'pickup' : 'pickups'} recorded",
              child: Row(children: summaryMetrics),
            ),
            const SizedBox(height: 24),
            Expanded(child: OperatorHistoryTabs(tabs: tabs)),
          ],
        );
      },
    );
  }
}
