import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

String _formatChartDate(String dateStr) {
  final parts = dateStr.split('-');
  if (parts.length == 3) {
    return '${parts[1]}/${parts[2]}';
  }
  return dateStr;
}

String _formatChartCurrency(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

class AttendanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const AttendanceChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(message: 'No attendance data available');
    }

    final dates = data.map((e) => _formatChartDate(e['date'] as String)).toList();
    final fullCounts =
        data.map((e) => (e['full_count'] as num?)?.toInt() ?? 0).toList();
    final halfCounts =
        data.map((e) => (e['half_count'] as num?)?.toInt() ?? 0).toList();
    final absentCounts =
        data.map((e) => (e['absent_count'] as num?)?.toInt() ?? 0).toList();

    final maxValue = [fullCounts, halfCounts, absentCounts]
        .expand((e) => e)
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Worker Attendance (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _LegendItem(color: Color(0xFF2E7D32), label: 'Full'),
                _LegendItem(color: Color(0xFFF57C00), label: 'Half'),
                _LegendItem(color: Color(0xFFD32F2F), label: 'Absent'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxValue / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (dates.length / 6)
                            .ceil()
                            .toDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dates[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: (maxValue / 4)
                            .ceilToDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _lineBarData(fullCounts, const Color(0xFF2E7D32)),
                    _lineBarData(halfCounts, const Color(0xFFF57C00)),
                    _lineBarData(absentCounts, const Color(0xFFD32F2F)),
                  ],
                  minX: 0,
                  maxX: (dates.length - 1).toDouble().clamp(0, double.infinity),
                  minY: 0,
                  maxY: maxValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(List<int> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index].toDouble()),
      ),
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.1),
      ),
    );
  }
}

class SiteProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const SiteProgressChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(message: 'No active sites');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              // Must stay tall enough for the axis + bar area. `length * 40`
              // gave a 40dp chart while the bottom titles reserved 100dp, so a
              // single site overflowed the card by ~60dp.
              height: (data.length * 40.0).clamp(180.0, 420.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index]['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        interval: 25,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    data.length,
                    (index) {
                      final progress =
                          (data[index]['progress_percentage'] as num?)
                                  ?.toDouble() ??
                              0.0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: progress.clamp(0, 100),
                            color: _getProgressColor(progress),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    },
                  ),
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 25) return const Color(0xFFD32F2F);
    if (progress < 50) return const Color(0xFFF57C00);
    if (progress < 75) return const Color(0xFF0288D1);
    return const Color(0xFF2E7D32);
  }
}

class MaterialUsageChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const MaterialUsageChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(message: 'No material usage data');
    }

    final maxValue = data
        .map((e) => (e['total_quantity'] as num?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a > b ? a : b)
        .clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 10 Materials by Usage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              // Same defect as Site Progress: the bar area shrank below the
              // bottom axis reservation for small data sets.
              height: (data.length * 35.0).clamp(180.0, 420.0),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index]['product_name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        interval: (maxValue / 4)
                            .ceilToDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    data.length,
                    (index) {
                      final quantity =
                          (data[index]['total_quantity'] as num?)?.toDouble() ??
                              0.0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: quantity,
                            color: cs.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    },
                  ),
                  maxY: maxValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpensesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const ExpensesChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(message: 'No expense data available');
    }

    final dates = data.map((e) => _formatChartDate(e['date'] as String)).toList();
    final amounts = data
        .map((e) => (e['total_amount'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final maxValue = amounts.isEmpty
        ? 1.0
        : amounts.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expenses (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxValue / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (dates.length / 6)
                            .ceil()
                            .toDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dates[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: (maxValue / 4)
                            .ceilToDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatChartCurrency(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        amounts.length,
                        (index) => FlSpot(index.toDouble(), amounts[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFFC2185B),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFFC2185B).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: (dates.length - 1).toDouble().clamp(0, double.infinity),
                  minY: 0,
                  maxY: maxValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentsChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const PaymentsChart({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (data.isEmpty) {
      return const _EmptyChart(message: 'No payment data available');
    }

    final dates = data.map((e) => _formatChartDate(e['date'] as String)).toList();
    final amounts = data
        .map((e) => (e['total_amount'] as num?)?.toDouble() ?? 0.0)
        .toList();

    final maxValue = amounts.isEmpty
        ? 1.0
        : amounts.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payments Received (Last 30 Days)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxValue / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (dates.length / 6)
                            .ceil()
                            .toDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dates[index],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: (maxValue / 4)
                            .ceilToDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatChartCurrency(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        amounts.length,
                        (index) => FlSpot(index.toDouble(), amounts[index]),
                      ),
                      isCurved: true,
                      color: const Color(0xFF2E7D32),
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: (dates.length - 1).toDouble().clamp(0, double.infinity),
                  minY: 0,
                  maxY: maxValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Reusable monthly trend line chart used by the Analytics screen. Renders one
/// or two currency series over month buckets (YYYY-MM). Read-only; the data is
/// pre-aggregated by [DatabaseHelper]. Shows an empty placeholder when no data.
class MonthlyTrendChart extends StatelessWidget {
  final String title;
  final List<String> months;
  final List<double> primary;
  final String primaryLabel;
  final Color primaryColor;
  final List<double>? secondary;
  final String? secondaryLabel;
  final Color? secondaryColor;

  const MonthlyTrendChart({
    required this.title,
    required this.months,
    required this.primary,
    required this.primaryLabel,
    required this.primaryColor,
    this.secondary,
    this.secondaryLabel,
    this.secondaryColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (months.isEmpty) {
      return _EmptyChart(message: 'No data for $title');
    }

    final all = <double>[...primary, if (secondary != null) ...secondary!];
    final maxValue = all.isEmpty
        ? 1.0
        : all.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

    LineChartBarData bar(List<double> values, Color color) => LineChartBarData(
          spots: List.generate(
            values.length,
            (i) => FlSpot(i.toDouble(), values[i]),
          ),
          isCurved: true,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: secondary == null,
            color: color.withValues(alpha: 0.1),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (secondary != null && secondaryLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _LegendItem(color: primaryColor, label: primaryLabel),
                  const SizedBox(width: 16),
                  _LegendItem(
                    color: secondaryColor ?? cs.secondary,
                    label: secondaryLabel!,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxValue / 4).ceilToDouble(),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (months.length / 6)
                            .ceil()
                            .toDouble()
                            .clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < months.length) {
                            final parts = months[index].split('-');
                            final label = parts.length == 2
                                ? '${parts[1]}/${parts[0].substring(2)}'
                                : months[index];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval:
                            (maxValue / 4).ceilToDouble().clamp(1, double.infinity),
                        getTitlesWidget: (value, meta) => Text(
                          _formatChartCurrency(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    bar(primary, primaryColor),
                    if (secondary != null)
                      bar(secondary!, secondaryColor ?? cs.secondary),
                  ],
                  minX: 0,
                  maxX: (months.length - 1).toDouble().clamp(0, double.infinity),
                  minY: 0,
                  maxY: maxValue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                size: 48,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
