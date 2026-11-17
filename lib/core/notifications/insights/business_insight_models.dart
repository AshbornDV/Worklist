// Phase 11 — Local Business Insight models.
//
// An [BusinessInsight] is a generated, human-readable observation derived
// purely from on-device SQLite data (no AI/cloud calls). Each insight belongs
// to a [InsightDomain] and carries a [InsightSeverity] so the UI can sort
// and color them. A [InsightSummary] groups insights into a Morning Briefing,
// Evening Summary, Weekly Report, or Monthly Report.

enum InsightDomain {
  payments,
  sites,
  workers,
  inventory,
  payroll,
  finance,
}

extension InsightDomainX on InsightDomain {
  String get label {
    switch (this) {
      case InsightDomain.payments:
        return 'Payments';
      case InsightDomain.sites:
        return 'Sites';
      case InsightDomain.workers:
        return 'Workers';
      case InsightDomain.inventory:
        return 'Inventory';
      case InsightDomain.payroll:
        return 'Payroll';
      case InsightDomain.finance:
        return 'Finance';
    }
  }

  /// Icon name (Material) used by the UI; kept as a string to avoid a UI
  /// import dependency in the domain model.
  String get icon {
    switch (this) {
      case InsightDomain.payments:
        return 'payments';
      case InsightDomain.sites:
        return 'sites';
      case InsightDomain.workers:
        return 'workers';
      case InsightDomain.inventory:
        return 'inventory';
      case InsightDomain.payroll:
        return 'payroll';
      case InsightDomain.finance:
        return 'finance';
    }
  }
}

enum InsightSeverity {
  info,
  attention,
  warning,
  critical,
}

extension InsightSeverityX on InsightSeverity {
  int get rank => index; // higher = more urgent
  String get label {
    switch (this) {
      case InsightSeverity.info:
        return 'Info';
      case InsightSeverity.attention:
        return 'Attention';
      case InsightSeverity.warning:
        return 'Warning';
      case InsightSeverity.critical:
        return 'Critical';
    }
  }
}

/// A single generated business insight.
class BusinessInsight {
  const BusinessInsight({
    required this.domain,
    required this.title,
    required this.body,
    this.severity = InsightSeverity.info,
    this.entityId,
    this.entityType,
    this.deepLink,
    this.deepLinkArgs,
  });

  final InsightDomain domain;
  final String title;
  final String body;
  final InsightSeverity severity;
  final String? entityId;
  final String? entityType;
  final String? deepLink;
  final Map<String, dynamic>? deepLinkArgs;

  /// Stable id (for diffing/animation) derived from content.
  String get id =>
      '${domain.name}:${title.hashCode}:${body.hashCode}';

  BusinessInsight copyWith({
    InsightDomain? domain,
    String? title,
    String? body,
    InsightSeverity? severity,
    String? entityId,
    String? entityType,
    String? deepLink,
    Map<String, dynamic>? deepLinkArgs,
  }) =>
      BusinessInsight(
        domain: domain ?? this.domain,
        title: title ?? this.title,
        body: body ?? this.body,
        severity: severity ?? this.severity,
        entityId: entityId ?? this.entityId,
        entityType: entityType ?? this.entityType,
        deepLink: deepLink ?? this.deepLink,
        deepLinkArgs: deepLinkArgs ?? this.deepLinkArgs,
      );

  Map<String, dynamic> toMap() => {
        'domain': domain.name,
        'title': title,
        'body': body,
        'severity': severity.name,
        if (entityId != null) 'entityId': entityId,
        if (entityType != null) 'entityType': entityType,
        if (deepLink != null) 'deepLink': deepLink,
        if (deepLinkArgs != null) 'deepLinkArgs': deepLinkArgs,
      };
}

/// A grouped, time-bounded digest of insights.
enum InsightSummaryKind {
  morningBriefing,
  eveningSummary,
  weeklyReport,
  monthlyReport,
}

extension InsightSummaryKindX on InsightSummaryKind {
  String get title {
    switch (this) {
      case InsightSummaryKind.morningBriefing:
        return 'Morning Briefing';
      case InsightSummaryKind.eveningSummary:
        return 'Evening Summary';
      case InsightSummaryKind.weeklyReport:
        return 'Weekly Report';
      case InsightSummaryKind.monthlyReport:
        return 'Monthly Report';
    }
  }

  /// When this summary should fire next, relative to [now].
  DateTime nextRun(DateTime now) {
    switch (this) {
      case InsightSummaryKind.morningBriefing:
        return DateTime(now.year, now.month, now.day, 8, 0);
      case InsightSummaryKind.eveningSummary:
        return DateTime(now.year, now.month, now.day, 19, 0);
      case InsightSummaryKind.weeklyReport:
        // Next Monday 09:00.
        final daysUntilMonday = (DateTime.monday - now.weekday) % 7;
        final base = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
        return DateTime(base.year, base.month, base.day, 9, 0);
      case InsightSummaryKind.monthlyReport:
        // First of next month 09:00.
        final nextMonth =
            now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        return DateTime(nextMonth.year, nextMonth.month, 1, 9, 0);
    }
  }
}

class InsightSummary {
  const InsightSummary({
    required this.kind,
    required this.generatedAt,
    required this.insights,
  });

  final InsightSummaryKind kind;
  final DateTime generatedAt;
  final List<BusinessInsight> insights;

  String get headline {
    if (insights.isEmpty) return '${kind.title}: all clear.';
    final critical = insights.where((i) => i.severity == InsightSeverity.critical).length;
    final warnings = insights.where((i) => i.severity == InsightSeverity.warning).length;
    return '${kind.title}: ${insights.length} insight(s) '
        '· $critical critical · $warnings warning';
  }

  Map<String, dynamic> toMap() => {
        'kind': kind.name,
        'generatedAt': generatedAt.toIso8601String(),
        'insights': insights.map((i) => i.toMap()).toList(),
      };
}
