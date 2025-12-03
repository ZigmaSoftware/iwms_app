class OperatorNextStop {
  const OperatorNextStop({
    this.label = "Sector 4 · Collection Lane",
    this.timeRemaining = "12 mins",
    this.routeName = "Ward 12 Route A",
    this.status = "En-route",
  });

  final String label;
  final String timeRemaining;
  final String routeName;
  final String status;
}

class OperatorCollectionSummary {
  const OperatorCollectionSummary({
    this.collectedAt = "Today · 08:35 AM",
    this.wetKg = 120,
    this.dryKg = 80,
    this.timeTaken = "15 mins",
  });

  final String collectedAt;
  final double wetKg;
  final double dryKg;
  final String timeTaken;
}

class OperatorAttendanceSummary {
  const OperatorAttendanceSummary({
    this.todayStatus = "Present",
    this.monthStat = "22 / 26 days",
    this.leaveBalance = "03 days",
    this.streakLabel = "Attendance streak",
    this.streakValue = "6 days",
  });

  final String todayStatus;
  final String monthStat;
  final String leaveBalance;
  final String streakLabel;
  final String streakValue;
}

class OperatorContactInfo {
  const OperatorContactInfo({
    this.phone = "-",
    this.email = "Not shared",
    this.designation = "Field Operator",
  });

  final String phone;
  final String email;
  final String designation;
}

class OperatorSessionDetails {
  const OperatorSessionDetails({
    required this.displayName,
    required this.operatorCode,
    this.wardLabel = "Ward 12",
    this.zoneLabel = "Zone 3",
    this.contactInfo = const OperatorContactInfo(),
  });

  final String displayName;
  final String operatorCode;
  final String wardLabel;
  final String zoneLabel;
  final OperatorContactInfo contactInfo;

  OperatorSessionDetails copyWith({
    String? displayName,
    String? operatorCode,
    String? wardLabel,
    String? zoneLabel,
    OperatorContactInfo? contactInfo,
  }) {
    return OperatorSessionDetails(
      displayName: displayName ?? this.displayName,
      operatorCode: operatorCode ?? this.operatorCode,
      wardLabel: wardLabel ?? this.wardLabel,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      contactInfo: contactInfo ?? this.contactInfo,
    );
  }
}
