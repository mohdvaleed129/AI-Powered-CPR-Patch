// dashboard_screen.dart — Premium redesign
// Features: animated ECG waveform, glowing vitals, live ticker, micro-animations

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bluetooth_service.dart';
import '../data_parser.dart';
import '../app_theme.dart';
import 'widgets/pulse_ring.dart';
import 'widgets/status_badge.dart';
import 'widgets/ecg_painter.dart';
import 'widgets/animated_counter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _ecgCtrl;
  late AnimationController _entryCtrl;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _ecgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();

    // Staggered entry animations for each card
    _slideAnims = List.generate(
        6,
            (i) => Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(i * 0.1, 0.6 + i * 0.07,
              curve: Curves.easeOutCubic),
        )));

    _fadeAnims = List.generate(
        6,
            (i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _entryCtrl,
          curve:
          Interval(i * 0.1, 0.6 + i * 0.07, curve: Curves.easeOut),
        )));
  }

  @override
  void dispose() {
    _ecgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _animated(int index, Widget child) => SlideTransition(
    position: _slideAnims[index],
    child: FadeTransition(opacity: _fadeAnims[index], child: child),
  );

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BluetoothService>();
    final data = ble.latestData;
    final isArrest = data?.status == CardiacStatus.arrest;
    final isAbnormal = data?.status == CardiacStatus.abnormal;
    final isCprOn = data?.cprActive == true;
    final isAlert = data?.alertSent == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top header bar ─────────────────────────────────────
              _animated(0, _TopHeader(ble: ble)),
              const SizedBox(height: 16),

              // ── Emergency banners ──────────────────────────────────
              if (isArrest)
                _animated(0, const _ArrestBanner()),
              if (isAlert && !isArrest)
                _animated(0, const _AlertBanner()),
              if (isArrest || isAlert) const SizedBox(height: 12),

              // ── ECG Waveform strip ─────────────────────────────────
              _animated(1, _EcgStrip(controller: _ecgCtrl, data: data)),
              const SizedBox(height: 14),

              // ── Big Heart Rate card ────────────────────────────────
              _animated(2, _HeartRateHero(data: data, isCprOn: isCprOn)),
              const SizedBox(height: 14),

              // ── Status + CPR row ───────────────────────────────────
              _animated(3,
                  Row(
                    children: [
                      Expanded(child: _StatusCard(data: data)),
                      const SizedBox(width: 12),
                      Expanded(child: _CprCard(data: data)),
                    ],
                  )),
              const SizedBox(height: 14),

              // ── Vitals row ─────────────────────────────────────────
              _animated(4, _VitalsRow(data: data)),
              const SizedBox(height: 14),

              // ── AI Confidence card ─────────────────────────────────
              _animated(5, _AiConfidenceCard(data: data)),
              const SizedBox(height: 14),

              // ── Device status card ─────────────────────────────────
              _animated(5, _DeviceStatusCard(ble: ble)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Header ─────────────────────────────────────────────────────────────
class _TopHeader extends StatelessWidget {
  final BluetoothService ble;
  const _TopHeader({required this.ble});

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI CPR MONITOR',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    color: AppTheme.cyan.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 3),
              const Text('Patient Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  )),
            ],
          ),
          const Spacer(),
          // Live indicator
          _LiveIndicator(connected: connected),
          const SizedBox(width: 10),
          // Time
          _ClockWidget(),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  final bool connected;
  const _LiveIndicator({required this.connected});

  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.connected ? AppTheme.green : AppTheme.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.connected
                    ? color.withValues(alpha: 0.5 + _ctrl.value * 0.5)
                    : color,
                boxShadow: widget.connected
                    ? [
                  BoxShadow(
                      color: color.withValues(
                          alpha: _ctrl.value * 0.6),
                      blurRadius: 6)
                ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.connected ? 'LIVE' : 'OFFLINE',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatefulWidget {
  @override
  State<_ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<_ClockWidget> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _updateTime();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(_updateTime);
      return mounted;
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _time =
    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(_time,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
          fontFamily: 'Courier',
        ));
  }
}

// ── ECG Strip ──────────────────────────────────────────────────────────────
class _EcgStrip extends StatelessWidget {
  final AnimationController controller;
  final PatchData? data;
  const _EcgStrip({required this.controller, required this.data});

  Color get _lineColor {
    switch (data?.status) {
      case CardiacStatus.arrest:
        return AppTheme.red;
      case CardiacStatus.abnormal:
        return AppTheme.yellow;
      default:
        return AppTheme.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      clipBehavior: Clip.hardEdge,
      decoration: AppTheme.glassCard(
          borderColor: _lineColor, borderOpacity: 0.2, glowOpacity: 0.05),
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _EcgGridPainter(color: _lineColor),
            ),
          ),
          // Animated waveform
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) => CustomPaint(
                painter: EcgWaveformPainter(
                  progress: controller.value,
                  color: _lineColor,
                  isArrest: data?.status == CardiacStatus.arrest,
                ),
              ),
            ),
          ),
          // Label
          Positioned(
            left: 12,
            top: 10,
            child: Text('ECG',
                style: TextStyle(
                  color: _lineColor.withValues(alpha: 0.7),
                  fontSize: 9,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                )),
          ),
          Positioned(
            right: 12,
            top: 10,
            child: Text('LEAD II',
                style: TextStyle(
                  color: _lineColor.withValues(alpha: 0.5),
                  fontSize: 9,
                  letterSpacing: 1.5,
                )),
          ),
        ],
      ),
    );
  }
}

class _EcgGridPainter extends CustomPainter {
  final Color color;
  _EcgGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;
    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_EcgGridPainter old) => old.color != color;
}

// ── Heart Rate Hero Card ───────────────────────────────────────────────────
class _HeartRateHero extends StatelessWidget {
  final PatchData? data;
  final bool isCprOn;
  const _HeartRateHero({required this.data, required this.isCprOn});

  @override
  Widget build(BuildContext context) {
    final hr = data?.heartRate;
    final color = isCprOn ? AppTheme.red : AppTheme.cyan;

    return Container(
      decoration: AppTheme.glassCard(
          borderColor: color, borderOpacity: 0.3, glowOpacity: 0.08),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: HR number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEART RATE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      color: color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    hr != null
                        ? AnimatedCounter(
                      value: hr,
                      style: TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -3,
                        height: 1,
                      ),
                    )
                        : Text('--',
                        style: TextStyle(
                          fontSize: 76,
                          fontWeight: FontWeight.w900,
                          color: color.withValues(alpha: 0.4),
                          height: 1,
                        )),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 6),
                      child: Text('BPM',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: color.withValues(alpha: 0.6),
                            letterSpacing: 1,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Mini HR bar indicator
                if (hr != null) _HrBar(hr: hr, color: color),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: Pulse ring
          PulseRing(
            active: isCprOn || (data?.status == CardiacStatus.arrest),
            color: color,
            size: 80,
            child: Icon(
              isCprOn ? Icons.favorite : Icons.monitor_heart,
              color: color,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HrBar extends StatelessWidget {
  final int hr;
  final Color color;
  const _HrBar({required this.hr, required this.color});

  @override
  Widget build(BuildContext context) {
    // Normal HR: 60-100
    final norm = (hr.clamp(40, 160) - 40) / 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('40', style: TextStyle(color: AppTheme.textTertiary, fontSize: 9)),
            const Spacer(),
            Text('100', style: TextStyle(color: AppTheme.textTertiary, fontSize: 9)),
            const Spacer(),
            Text('160', style: TextStyle(color: AppTheme.textTertiary, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Container(height: 5, color: AppTheme.bg3),
              // Normal zone indicator
              Positioned(
                left: MediaQuery.of(context).size.width * 0.15,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.17,
                  height: 5,
                  color: AppTheme.green.withValues(alpha: 0.15),
                ),
              ),
              FractionallySizedBox(
                widthFactor: norm,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppTheme.green,
                      color,
                    ]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Status Card ────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final PatchData? data;
  const _StatusCard({required this.data});

  Color get _color {
    switch (data?.status) {
      case CardiacStatus.normal:    return AppTheme.green;
      case CardiacStatus.abnormal:  return AppTheme.yellow;
      case CardiacStatus.arrest:    return AppTheme.red;
      default:                      return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(borderColor: _color, borderOpacity: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CARDIAC STATUS',
              style: TextStyle(
                fontSize: 9, letterSpacing: 2,
                color: _color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          // Big status icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.1),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Icon(
              data?.status == CardiacStatus.arrest
                  ? Icons.warning_rounded
                  : data?.status == CardiacStatus.abnormal
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: _color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          StatusBadge(
            label: data?.statusLabel ?? 'N/A',
            color: _color,
          ),
        ],
      ),
    );
  }
}

// ── CPR Card ───────────────────────────────────────────────────────────────
class _CprCard extends StatelessWidget {
  final PatchData? data;
  const _CprCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final active = data?.cprActive ?? false;
    final color = active ? AppTheme.red : AppTheme.green;

    return Container(
      decoration: AppTheme.glassCard(borderColor: color, borderOpacity: 0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CPR STATUS',
              style: TextStyle(
                fontSize: 9, letterSpacing: 2,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(
              active ? Icons.medical_services : Icons.medical_services_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          StatusBadge(
            label: active ? 'ACTIVE' : 'STANDBY',
            color: color,
          ),
        ],
      ),
    );
  }
}

// ── Vitals Row ─────────────────────────────────────────────────────────────
class _VitalsRow extends StatelessWidget {
  final PatchData? data;
  const _VitalsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniVital(
            label: 'RHYTHM',
            value: data?.status == CardiacStatus.normal
                ? 'SINUS'
                : data?.status == CardiacStatus.abnormal
                ? 'IRREG.'
                : data?.status == CardiacStatus.arrest
                ? 'VF/VT'
                : '--',
            color: AppTheme.purple,
            icon: Icons.timeline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniVital(
            label: 'ALERT',
            value: data?.alertSent == true ? 'SENT' : 'NONE',
            color: data?.alertSent == true ? AppTheme.red : AppTheme.green,
            icon: Icons.notifications_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniVital(
            label: 'AI CONF.',
            value: '${data?.aiConfidence ?? 0}%',
            color: AppTheme.orange,
            icon: Icons.psychology_outlined,
          ),
        ),
      ],
    );
  }
}

class _MiniVital extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _MiniVital(
      {required this.label,
        required this.value,
        required this.color,
        required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(borderColor: color, borderOpacity: 0.2),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                color: AppTheme.textTertiary,
                fontSize: 8,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── AI Confidence Card ──────────────────────────────────────────────────────
class _AiConfidenceCard extends StatelessWidget {
  final PatchData? data;
  const _AiConfidenceCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final conf = data?.aiConfidence ?? 0;
    final color = conf > 85
        ? AppTheme.red
        : conf > 50
        ? AppTheme.yellow
        : AppTheme.green;

    return Container(
      decoration: AppTheme.glassCard(borderColor: AppTheme.purple),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.purple, size: 18),
              const SizedBox(width: 8),
              const Text('AI DETECTION ENGINE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: AppTheme.purple,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              ShaderMask(
                shaderCallback: (b) =>
                    LinearGradient(colors: [color, AppTheme.purple])
                        .createShader(b),
                child: Text('$conf%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Segmented confidence bar
          _SegmentedBar(value: conf / 100, color: color),
          const SizedBox(height: 10),
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(8),
              border:
              Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conf > 85
                        ? 'HIGH RISK — Immediate intervention recommended'
                        : conf > 50
                        ? 'ELEVATED — Monitoring closely for changes'
                        : 'STABLE — Patient within normal parameters',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  final double value;
  final Color color;
  const _SegmentedBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    const segments = 20;
    final filled = (value * segments).round();
    return Row(
      children: List.generate(segments, (i) {
        final active = i < filled;
        return Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: active
                  ? color.withValues(alpha: 0.7 + i / segments * 0.3)
                  : AppTheme.bg3,
              borderRadius: BorderRadius.circular(2),
              boxShadow: active
                  ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4)
              ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// ── Device Status Card ─────────────────────────────────────────────────────
class _DeviceStatusCard extends StatelessWidget {
  final BluetoothService ble;
  const _DeviceStatusCard({required this.ble});

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;
    final color = connected ? AppTheme.cyan : AppTheme.textTertiary;

    return Container(
      decoration: AppTheme.glassCard(borderColor: color, borderOpacity: 0.2),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ble.connectedDevice?.platformName.isNotEmpty == true
                      ? ble.connectedDevice!.platformName
                      : 'No Device Connected',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(ble.statusMessage,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          // Data rate indicator
          if (connected)
            Column(
              children: [
                Text('250',
                    style: TextStyle(
                      color: AppTheme.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    )),
                const Text('Hz',
                    style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 9,
                        letterSpacing: 1)),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Emergency Banners ──────────────────────────────────────────────────────
class _ArrestBanner extends StatefulWidget {
  const _ArrestBanner();
  @override
  State<_ArrestBanner> createState() => _ArrestBannerState();
}

class _ArrestBannerState extends State<_ArrestBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.red.withValues(alpha: 0.08 + _ctrl.value * 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.red.withValues(alpha: 0.4 + _ctrl.value * 0.4),
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color:
                AppTheme.red.withValues(alpha: _ctrl.value * 0.2),
                blurRadius: 20,
                spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.emergency,
                color: AppTheme.red.withValues(alpha: 0.6 + _ctrl.value * 0.4),
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠ CARDIAC ARREST DETECTED',
                      style: TextStyle(
                        color: AppTheme.red
                            .withValues(alpha: 0.7 + _ctrl.value * 0.3),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      )),
                  const SizedBox(height: 2),
                  const Text('CPR COMPRESSIONS ACTIVATED',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.orange.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active,
              color: AppTheme.orange, size: 20),
          const SizedBox(width: 10),
          const Text('🚨 EMERGENCY ALERT DISPATCHED',
              style: TextStyle(
                color: AppTheme.orange,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              )),
        ],
      ),
    );
  }
}
