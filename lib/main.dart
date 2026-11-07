// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'bluetooth_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/graph_screen.dart';
import 'screens/bluetooth_screen.dart';
import 'screens/dataset_screen.dart';
import 'screens/flow_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg2,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(ChangeNotifierProvider(
    create: (_) => BluetoothService(),
    child: const CprMonitorApp(),
  ));
}

class CprMonitorApp extends StatelessWidget {
  const CprMonitorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const SplashScreen(),
  );
}

// ── Splash Screen ──────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _ringScale =
        Tween<double>(begin: 0.6, end: 1.4).animate(_ringCtrl);
    _ringOpacity =
        Tween<double>(begin: 0.8, end: 0.0).animate(_ringCtrl);
    _logoFade =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeCtrl);
    _logoScale =
        Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _fadeCtrl, curve: Curves.elasticOut));

    _fadeCtrl.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainShell(),
              transitionDuration: const Duration(milliseconds: 600),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
            ));
      }
    });
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg0,
      body: Stack(
        children: [
          // Background grid
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          AppTheme.scanlineOverlay(opacity: 0.04),
          Center(
            child: FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing ring + heart icon
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _ringCtrl,
                            builder: (_, __) => Transform.scale(
                              scale: _ringScale.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.red
                                        .withValues(alpha: _ringOpacity.value),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.red.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: AppTheme.red.withValues(alpha: 0.4),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.favorite,
                                color: AppTheme.red, size: 42),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    // App name
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppTheme.cyanGrad.createShader(b),
                      child: const Text('AI CPR MONITOR',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          )),
                    ),
                    const SizedBox(height: 8),
                    const Text('CARDIAC INTELLIGENCE SYSTEM',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w500,
                        )),
                    const SizedBox(height: 40),
                    // Loading bar
                    _AnimatedLoadingBar(),
                    const SizedBox(height: 12),
                    const Text('INITIALIZING SYSTEMS...',
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 10,
                          letterSpacing: 2,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoadingBar extends StatefulWidget {
  @override
  State<_AnimatedLoadingBar> createState() => _AnimatedLoadingBarState();
}

class _AnimatedLoadingBarState extends State<_AnimatedLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _prog;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..forward();
    _prog = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _prog,
      builder: (_, __) => Container(
        width: 200,
        height: 3,
        decoration: BoxDecoration(
          color: AppTheme.bg3,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _prog.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cyanGrad,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.cyan.withValues(alpha: 0.6),
                    blurRadius: 6)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Background grid painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cyan.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ── Main Shell ─────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _arrestCtrl;
  late Animation<double> _arrestFade;

  final List<Widget> _screens = const [
    DashboardScreen(),
    GraphScreen(),
    BluetoothScreen(),
    DatasetScreen(),
    FlowScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _arrestCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    _arrestFade =
        Tween<double>(begin: 0.6, end: 1.0).animate(_arrestCtrl);
  }

  @override
  void dispose() {
    _arrestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BluetoothService>();
    final isArrest = ble.latestData?.status.name == 'arrest';
    final isCpr = ble.latestData?.cprActive == true;

    return Scaffold(
      backgroundColor: AppTheme.bg1,
      // Top arrest banner
      appBar: isArrest
          ? PreferredSize(

        preferredSize: const Size.fromHeight(40),
        child: FadeTransition(
          opacity: _arrestFade,
          child: Container(
            color: AppTheme.red.withValues(alpha: 0.9),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emergency,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    '⚠  CARDIAC ARREST DETECTED  —  CPR ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.emergency,
                      color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
      )
          : null,
      body: Stack(
        children: [
          // Subtle background grid always visible
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          IndexedStack(index: _currentIndex, children: _screens),
        ],
      ),
      bottomNavigationBar: _FancyNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        hasAlert: isArrest || isCpr,
      ),
    );
  }
}

// ── Custom Nav Bar ─────────────────────────────────────────────────────────
class _FancyNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool hasAlert;

  const _FancyNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.hasAlert,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.monitor_heart_outlined,
          activeIcon: Icons.monitor_heart, label: 'Monitor',
          hasAlert: hasAlert && currentIndex != 0),
      _NavItem(icon: Icons.show_chart, label: 'Graph'),
      _NavItem(icon: Icons.bluetooth_outlined,
          activeIcon: Icons.bluetooth, label: 'BLE'),
      _NavItem(icon: Icons.table_chart_outlined,
          activeIcon: Icons.table_chart, label: 'Data'),
      _NavItem(icon: Icons.account_tree_outlined,
          activeIcon: Icons.account_tree, label: 'Flow'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg2,
        border: Border(
            top: BorderSide(
                color: AppTheme.cyan.withValues(alpha: 0.15), width: 1)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.bg0.withValues(alpha: 0.8),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Selected indicator line
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 24 : 0,
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            gradient: selected ? AppTheme.cyanGrad : null,
                            borderRadius: BorderRadius.circular(1),
                            boxShadow: selected
                                ? [
                              BoxShadow(
                                  color: AppTheme.cyan
                                      .withValues(alpha: 0.8),
                                  blurRadius: 6)
                            ]
                                : null,
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              selected
                                  ? (items[i].activeIcon ?? items[i].icon)
                                  : items[i].icon,
                              color: selected
                                  ? AppTheme.cyan
                                  : AppTheme.textTertiary,
                              size: 22,
                            ),
                            if (items[i].hasAlert)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: AppTheme.red
                                              .withValues(alpha: 0.8),
                                          blurRadius: 4)
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.cyan
                                : AppTheme.textTertiary,
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            letterSpacing: selected ? 1.0 : 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool hasAlert;
  const _NavItem(
      {required this.icon,
        this.activeIcon,
        required this.label,
        this.hasAlert = false});
}
