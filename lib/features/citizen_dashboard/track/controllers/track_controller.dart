import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/waste_period.dart';
import '../models/waste_summary.dart';
import '../services/track_service.dart';

class TrackController extends ChangeNotifier {
  TrackController(this._service);

  final TrackService _service;

  final DateFormat _monthKeyFormatter = DateFormat('yyyy-MM');
  final DateFormat _dateKeyFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat displayFormat = DateFormat('EEEE, dd MMM yyyy');
  final DateFormat shortDisplayFormat = DateFormat('d MMM');
  final NumberFormat weightFormatter = NumberFormat.decimalPattern();
  final NumberFormat averageFormatter = NumberFormat('#,##0.00');

  WastePeriod selectedPeriod = WastePeriod.daily;
  DateTime selectedDate = DateTime.now();
  String? _trackMonthKey;
  Map<String, WasteSummary> summaries = {};
  bool loading = false;
  String? error;

  WasteSummary? get currentSummary =>
      summaries[_dateKeyFormatter.format(_normalize(selectedDate))];

  Future<void> refresh({bool force = false}) async {
    final monthStart = DateTime(selectedDate.year, selectedDate.month, 1);
    final monthKey = _monthKeyFormatter.format(monthStart);
    if (!force && _trackMonthKey == monthKey && summaries.isNotEmpty) {
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      final data = await _service.fetchMonthlySummaries(selectedDate);
      summaries = data;
      _trackMonthKey = monthKey;
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = 'Unable to load live data. Pull down to retry.';
      notifyListeners();
    }
  }

  void setPeriod(WastePeriod period) {
    if (selectedPeriod == period) return;
    selectedPeriod = period;
    notifyListeners();
  }

  Future<void> pickDate(DateTime date) async {
    selectedDate = _normalize(date);
    await refresh();
    notifyListeners();
  }

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
