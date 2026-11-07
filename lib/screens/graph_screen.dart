// graph_screen.dart — Enhanced
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../bluetooth_service.dart';
import '../data_parser.dart';
import '../app_theme.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BluetoothService>();
    final history = ble.dataHistory;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TELEMETRY',
                        style: TextStyle(
                          fontSize: 10, letterSpacing: 3,
                          color: AppTheme.cyan, fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: 3),
                    Text('Heart Rate Graph',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        )),
                  ],
                ),
              ),

              // Stats row
              if (history.isNotEmpty) ...[
                _StatsRow(history: history),
                const SizedBox(height: 14),
              ],

              // Chart
              Expanded(
                child: history.isEmpty
                    ? _EmptyChart()
                    : _HrChart(history: history),
              ),

              const SizedBox(height: 14),
              _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<PatchData> history;
  const _StatsRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final hrs = history.map((d) => d.heartRate).where((h) => h > 0).toList();
    final avg = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a + b) ~/ hrs.length;
    final max = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a > b ? a : b);
    final min = hrs.isEmpty ? 0 : hrs.reduce((a, b) => a < b ? a : b);

    return Row(
      children: [
        Expanded(child: _StatTile(label: 'AVERAGE', value: '$avg', unit: 'BPM', color: AppTheme.cyan)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'PEAK', value: '$max', unit: 'BPM', color: AppTheme.red)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'LOW', value: '$min', unit: 'BPM', color: AppTheme.green)),
        const SizedBox(width: 10),
        Expanded(child: _StatTile(label: 'SAMPLES', value: '${history.length}', unit: 'PTS', color: AppTheme.purple)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: AppTheme.glassCard(borderColor: color, borderOpacity: 0.25),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppTheme.textTertiary, fontSize: 8, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(unit, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _HrChart extends StatelessWidget {
  final List<PatchData> history;
  const _HrChart({required this.history});

  List<FlSpot> get _spots =>
      List.generate(history.length, (i) => FlSpot(i.toDouble(), history[i].heartRate.toDouble()));

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    final maxY = history.map((d) => d.heartRate).fold(0, (a, b) => a > b ? a : b) + 25.0;

    return Container(
      decoration: AppTheme.glassCard(borderColor: AppTheme.cyan, borderOpacity: 0.2),
      padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 9)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 10,
                getTitlesWidget: (v, _) => Text('${(v * 2).toInt()}s',
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 9)),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            // Shadow line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.cyan.withValues(alpha: 0.0),
              barWidth: 0,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.18),
                    AppTheme.cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            // Main line
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.cyan,
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, i) {
                  Color c;
                  switch (history[i].status) {
                    case CardiacStatus.arrest: c = AppTheme.red; break;
                    case CardiacStatus.abnormal: c = AppTheme.yellow; break;
                    default: c = AppTheme.cyan;
                  }
                  return FlDotCirclePainter(
                      radius: 2.5,
                      color: c,
                      strokeWidth: 1,
                      strokeColor: c.withValues(alpha: 0.3));
                },
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppTheme.bg3,
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${s.y.toInt()} BPM',
                const TextStyle(
                    color: AppTheme.cyan,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(borderColor: AppTheme.textTertiary, borderOpacity: 0.15),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, color: AppTheme.textTertiary, size: 48),
            SizedBox(height: 12),
            Text('No data yet',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Connect device or start Demo Mode',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(color: AppTheme.cyan, label: 'Normal'),
        const SizedBox(width: 20),
        _Dot(color: AppTheme.yellow, label: 'Abnormal'),
        const SizedBox(width: 20),
        _Dot(color: AppTheme.red, label: 'Arrest'),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
