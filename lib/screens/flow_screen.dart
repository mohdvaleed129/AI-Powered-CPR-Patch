// flow_screen.dart — Enhanced animated pipeline
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bluetooth_service.dart';
import '../data_parser.dart';
import '../app_theme.dart';

class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});
  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  late List<Animation<double>> _pulses;
  late AnimationController _flowCtrl;
  late Animation<double> _flowAnim;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
        4,
            (i) => AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 900 + i * 100))
          ..repeat(reverse: true));
    _pulses = _ctrls
        .map((c) => Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    _flowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _flowAnim = Tween<double>(begin: 0, end: 1).animate(_flowCtrl);
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    _flowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BluetoothService>();
    final data = ble.latestData;

    final stages = [
      _Stage(
        icon: Icons.sensors,
        title: 'ECG SENSOR',
        subtitle: ble.isConnected ? 'Signal: 250 Hz' : 'Awaiting signal',
        active: ble.isConnected,
        color: AppTheme.cyan,
        detail: 'Wearable patch captures 12-lead ECG at 250Hz and streams via BLE 5.0',
      ),
      _Stage(
        icon: Icons.psychology,
        title: 'AI DETECTION',
        subtitle: data != null ? 'Confidence: ${data.aiConfidence}%' : 'Model idle',
        active: data != null,
        color: AppTheme.purple,
        detail: 'On-device neural network classifies rhythm in <50ms with 97% accuracy',
      ),
      _Stage(
        icon: Icons.health_and_safety,
        title: 'CPR MODULE',
        subtitle: data?.cprActive == true ? 'COMPRESSIONS ACTIVE' : 'Standby',
        active: data?.cprActive == true,
        color: AppTheme.red,
        detail: 'Automated compression feedback at 100-120 bpm with 5-6cm depth guidance',
      ),
      _Stage(
        icon: Icons.cell_tower,
        title: 'ALERT SYSTEM',
        subtitle: data?.alertSent == true ? 'Emergency dispatched 🚨' : 'No alert',
        active: data?.alertSent == true,
        color: AppTheme.yellow,
        detail: 'Simultaneous SMS + push dispatch to EMS and emergency contacts in <2s',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SYSTEM FLOW',
                        style: TextStyle(
                          fontSize: 10, letterSpacing: 3,
                          color: AppTheme.cyan, fontWeight: FontWeight.w700,
                        )),
                    SizedBox(height: 3),
                    Text('AI Pipeline',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                        )),
                  ],
                ),
              ),

              // Pipeline
              ...List.generate(stages.length, (i) => Column(
                children: [
                  ScaleTransition(
                    scale: stages[i].active ? _pulses[i] : const AlwaysStoppedAnimation(1.0),
                    child: _StageCard(stage: stages[i]),
                  ),
                  if (i < stages.length - 1)
                    _FlowArrow(
                      active: stages[i].active,
                      animation: _flowAnim,
                    ),
                ],
              )),

              const SizedBox(height: 20),
              _SummaryCard(data: data),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage {
  final IconData icon;
  final String title, subtitle, detail;
  final bool active;
  final Color color;
  const _Stage({required this.icon, required this.title, required this.subtitle,
    required this.detail, required this.active, required this.color});
}

class _StageCard extends StatelessWidget {
  final _Stage stage;
  const _StageCard({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(
        borderColor: stage.active ? stage.color : AppTheme.textTertiary,
        borderOpacity: stage.active ? 0.35 : 0.15,
        glowOpacity: stage.active ? 0.08 : 0.0,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (stage.active ? stage.color : AppTheme.textTertiary).withValues(alpha: 0.1),
              border: Border.all(
                color: (stage.active ? stage.color : AppTheme.divider).withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(stage.icon,
                color: stage.active ? stage.color : AppTheme.textTertiary,
                size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(stage.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 1,
                        )),
                    const SizedBox(width: 8),
                    if (stage.active)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('ACTIVE',
                            style: TextStyle(
                              color: stage.color,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            )),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(stage.subtitle,
                    style: TextStyle(
                      color: stage.active ? stage.color : AppTheme.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text(stage.detail,
                    style: const TextStyle(
                        color: AppTheme.textTertiary, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowArrow extends StatelessWidget {
  final bool active;
  final Animation<double> animation;
  const _FlowArrow({required this.active, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated data flow dots
            if (active)
              AnimatedBuilder(
                animation: animation,
                builder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (animation.value + i * 0.33) % 1.0;
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cyan.withValues(alpha: phase),
                      ),
                    );
                  }),
                ),
              )
            else
              Container(width: 1, height: 16,
                  color: AppTheme.divider),
            Icon(Icons.keyboard_arrow_down,
                color: active ? AppTheme.cyan : AppTheme.divider, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final PatchData? data;
  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isArrest = data?.status == CardiacStatus.arrest;
    final isAbnormal = data?.status == CardiacStatus.abnormal;

    Color color;
    String title, msg;
    IconData icon;

    if (isArrest) {
      color = AppTheme.red; icon = Icons.emergency;
      title = 'CRITICAL STATE';
      msg = 'Full pipeline engaged — all systems responding to cardiac arrest';
    } else if (isAbnormal) {
      color = AppTheme.yellow; icon = Icons.warning_amber_rounded;
      title = 'ELEVATED RISK';
      msg = 'Abnormal rhythm detected — AI monitoring at maximum sensitivity';
    } else if (data != null) {
      color = AppTheme.green; icon = Icons.check_circle;
      title = 'SYSTEMS NORMAL';
      msg = 'All pipeline stages operational — patient vitals stable';
    } else {
      color = AppTheme.textTertiary; icon = Icons.info_outline;
      title = 'SYSTEM IDLE';
      msg = 'Connect a device or launch Demo Mode to activate the pipeline';
    }

    return Container(
      decoration: AppTheme.glassCard(borderColor: color, borderOpacity: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w800,
                        fontSize: 13, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(msg,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
