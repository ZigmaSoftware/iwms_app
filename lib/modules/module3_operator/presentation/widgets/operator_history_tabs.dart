import 'package:flutter/material.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/theme/operator_theme.dart';

class OperatorHistoryEntry {
  const OperatorHistoryEntry({
    required this.routeName,
    required this.location,
    required this.timestamp,
    required this.totalKg,
    required this.wetKg,
    required this.dryKg,
    this.otherKg = 0,
  });

  final String routeName;
  final String location;
  final String timestamp;
  final double totalKg;
  final double wetKg;
  final double dryKg;
  final double otherKg;
}

class OperatorHistoryTabData {
  const OperatorHistoryTabData({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<OperatorHistoryEntry> entries;
}

class OperatorHistoryTabs extends StatelessWidget {
  const OperatorHistoryTabs({
    super.key,
    required this.tabs,
  });

  final List<OperatorHistoryTabData> tabs;

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const Center(child: Text('No history found'));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: OperatorTheme.chipRadius,
              boxShadow: OperatorTheme.softShadow,
            ),
            child: TabBar(
              labelColor: OperatorTheme.primary,
              unselectedLabelColor: OperatorTheme.mutedText,
              indicator: BoxDecoration(
                color: OperatorTheme.primary.withOpacity(0.12),
                borderRadius: OperatorTheme.chipRadius,
              ),
              tabs: tabs
                  .map(
                    (tab) => Tab(
                      height: 46,
                      child: Text(
                        tab.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: tabs
                  .map(
                    (tab) => _OperatorHistoryList(entries: tab.entries),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorHistoryList extends StatelessWidget {
  const _OperatorHistoryList({required this.entries});

  final List<OperatorHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'No records for this filter.',
          style: TextStyle(color: OperatorTheme.mutedText),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _OperatorHistoryCard(entry: entry);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: entries.length,
    );
  }
}

class _OperatorHistoryCard extends StatelessWidget {
  const _OperatorHistoryCard({required this.entry});

  final OperatorHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: OperatorTheme.cardRadius,
        boxShadow: OperatorTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: OperatorTheme.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: OperatorTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.routeName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: OperatorTheme.strongText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.location,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: OperatorTheme.mutedText),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.totalKg.toStringAsFixed(1)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: OperatorTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    entry.timestamp,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: OperatorTheme.mutedText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: OperatorTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: _buildMetricColumns(theme),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMetricColumns(ThemeData theme) {
    final metrics = <_HistoryMetric>[
      _HistoryMetric(
        label: 'Dry Waste',
        value: entry.dryKg,
        alignment: CrossAxisAlignment.start,
      ),
      _HistoryMetric(
        label: 'Wet Waste',
        value: entry.wetKg,
        alignment: CrossAxisAlignment.end,
      ),
    ];

    if (entry.otherKg > 0) {
      metrics.add(
        _HistoryMetric(
          label: 'Mixed / Other',
          value: entry.otherKg,
          alignment: CrossAxisAlignment.end,
        ),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < metrics.length; i++) {
      final metric = metrics[i];
      children.add(
        Expanded(
          child: Column(
            crossAxisAlignment: metric.alignment,
            children: [
              Text(
                '${metric.value.toStringAsFixed(1)} kg',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                metric.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: OperatorTheme.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
      if (i != metrics.length - 1) {
        children.add(Container(
          width: 1,
          height: 34,
          color: Colors.black.withOpacity(0.07),
        ));
      }
    }
    return children;
  }
}

class _HistoryMetric {
  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final double value;
  final CrossAxisAlignment alignment;
}
