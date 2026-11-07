// dataset_screen.dart — V2 Fixed for new AppTheme
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import '../data_parser.dart';
import '../app_theme.dart';

class DatasetScreen extends StatefulWidget {
  const DatasetScreen({super.key});
  @override
  State<DatasetScreen> createState() => _DatasetScreenState();
}

class _DatasetScreenState extends State<DatasetScreen>
    with SingleTickerProviderStateMixin {
  List<PatchData> _rows = [];
  bool _loading = false;
  String _error = '';
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAsset();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAsset() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final raw = await rootBundle.loadString('assets/sample_data.csv');
      final table = const CsvToListConverter().convert(raw, eol: '\n');
      setState(() { _rows = CsvParser.fromCsvRows(table); _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DATASET',
                          style: TextStyle(fontSize: 10, letterSpacing: 3,
                              color: AppTheme.cyan, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text('CSV Viewer',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimary)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _loadAsset,
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.cyan.withValues(alpha: 0.08),
                      ),
                      child: const Icon(Icons.refresh, color: AppTheme.cyan, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppTheme.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppTheme.cyan.withValues(alpha: 0.4)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.cyan,
                  unselectedLabelColor: AppTheme.textTertiary,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.5),
                  tabs: const [Tab(text: 'TABLE'), Tab(text: 'GRAPH')],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.cyan))
                  : _error.isNotEmpty
                  ? _ErrorView(message: _error)
                  : _rows.isEmpty
                  ? const _EmptyView()
                  : TabBarView(
                controller: _tabs,
                children: [
                  _TableView(rows: _rows),
                  _DatasetGraph(rows: _rows),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final List<PatchData> rows;
  const _TableView({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: AppTheme.bg3, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: ['#', 'TIME', 'HR', 'STATUS', 'CPR', 'ALERT']
                  .asMap().entries.map((e) => Expanded(
                flex: e.key == 1 ? 3 : 2,
                child: Text(e.value,
                    style: const TextStyle(color: AppTheme.textTertiary,
                        fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              )).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (ctx, i) => _TableRow(data: rows[i], index: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final PatchData data;
  final int index;
  const _TableRow({required this.data, required this.index});

  Color get _statusColor {
    switch (data.status) {
      case CardiacStatus.arrest:   return AppTheme.red;
      case CardiacStatus.abnormal: return AppTheme.yellow;
      default:                     return AppTheme.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bg2, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: Row(
        children: [
          Expanded(flex: 2,
              child: Text('${index + 1}', textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11))),
          Expanded(flex: 3,
              child: Text(
                  '${data.timestamp.hour.toString().padLeft(2,'0')}:'
                      '${data.timestamp.minute.toString().padLeft(2,'0')}:'
                      '${data.timestamp.second.toString().padLeft(2,'0')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
          Expanded(flex: 2,
              child: Text('${data.heartRate}', textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.cyan,
                      fontWeight: FontWeight.w700, fontSize: 12))),
          Expanded(flex: 2,
              child: Text(data.statusLabel, textAlign: TextAlign.center,
                  style: TextStyle(color: _statusColor,
                      fontWeight: FontWeight.w700, fontSize: 10))),
          Expanded(flex: 2,
              child: Text(data.cprActive ? 'ON' : 'OFF', textAlign: TextAlign.center,
                  style: TextStyle(
                      color: data.cprActive ? AppTheme.red : AppTheme.textTertiary,
                      fontWeight: FontWeight.w700, fontSize: 11))),
          Expanded(flex: 2,
              child: Icon(
                  data.alertSent ? Icons.warning_rounded : Icons.check_circle_outline,
                  color: data.alertSent ? AppTheme.red : AppTheme.green,
                  size: 16)),
        ],
      ),
    );
  }
}

class _DatasetGraph extends StatelessWidget {
  final List<PatchData> rows;
  const _DatasetGraph({required this.rows});

  @override
  Widget build(BuildContext context) {
    final spots = List.generate(rows.length,
            (i) => FlSpot(i.toDouble(), rows[i].heartRate.toDouble()));
    final maxY = rows.map((r) => r.heartRate)
        .fold(0, (a, b) => a > b ? a : b).toDouble() + 20;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: AppTheme.glassCard(borderColor: AppTheme.cyan, borderOpacity: 0.2),
        padding: const EdgeInsets.fromLTRB(4, 16, 16, 8),
        child: LineChart(LineChartData(
          minX: 0, maxX: (rows.length - 1).toDouble(), minY: 0, maxY: maxY,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppTheme.divider, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 34,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 9)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 20, interval: 5,
              getTitlesWidget: (v, _) => Text('${v.toInt()}',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 9)),
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots, isCurved: true,
              color: AppTheme.cyan.withValues(alpha: 0.0), barWidth: 0,
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.cyan.withValues(alpha: 0.18),
                    AppTheme.cyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
            LineChartBarData(
              spots: spots, isCurved: true, color: AppTheme.cyan, barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, i) {
                  Color c;
                  switch (rows[i].status) {
                    case CardiacStatus.arrest:   c = AppTheme.red; break;
                    case CardiacStatus.abnormal: c = AppTheme.yellow; break;
                    default:                     c = AppTheme.cyan;
                  }
                  return FlDotCirclePainter(
                      radius: 3, color: c,
                      strokeWidth: 1, strokeColor: c.withValues(alpha: 0.3));
                },
              ),
            ),
          ],
        )),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.red, size: 48),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ]),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.table_chart_outlined, color: AppTheme.textTertiary, size: 48),
      SizedBox(height: 12),
      Text('No data loaded',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16,
              fontWeight: FontWeight.w600)),
    ]),
  );
}