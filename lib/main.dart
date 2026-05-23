import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/land_converter_screen.dart';
import 'screens/bmi_calculator_screen.dart';
import 'screens/basic_calculator_screen.dart';
import 'screens/scientific_calculator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const UniToolsApp());
}

class UniToolsApp extends StatelessWidget {
  const UniToolsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniTools',
      theme: ThemeData(useMaterial3: true),
      home: const HomeMenuScreen(),
    );
  }
}

class HomeMenuScreen extends StatelessWidget {
  const HomeMenuScreen({super.key});
  static const String _version = 'v1.0';

  @override
  Widget build(BuildContext context) {
    // Cards data
    final apps = [
      _AppItem(
        number: 1, title: 'Land Measurement Converter',
        subtitle: 'Bigha · Katha · Acre · Decimel',
        icon: Icons.landscape_rounded,
        g1: const Color(0xFF1976D2), g2: const Color(0xFF26C6DA),
        screen: const LandConverterScreen(),
      ),
      _AppItem(
        number: 2, title: 'BMI Calculator',
        subtitle: 'Body Mass Index · Health Status',
        icon: Icons.monitor_weight_rounded,
        g1: const Color(0xFF43A047), g2: const Color(0xFF4DB6AC),
        screen: const BmiCalculatorScreen(),
      ),
      _AppItem(
        number: 3, title: 'Basic Calculator',
        subtitle: 'Arithmetic  ·  +  −  ×  ÷',
        icon: Icons.calculate_rounded,
        g1: const Color(0xFFF57C00), g2: const Color(0xFFFFCA28),
        screen: const BasicCalculatorScreen(),
      ),
      _AppItem(
        number: 4, title: 'Scientific Calculator',
        subtitle: 'sin · cos · log · √ · π · n!',
        icon: Icons.functions_rounded,
        g1: const Color(0xFF7B1FA2), g2: const Color(0xFFEC407A),
        screen: const ScientificCalculatorScreen(),
      ),
    ];

    // Background: light-to-mid blue glossy gradient — NOT dark
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // dark status-bar icons on light bg
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF0E2040),
                Color(0xFF00897B),
                Color(0xFF1565C0),
              ],
            ),
          ),
          child: Stack(children: [
            // ── Glossy top-shine overlay ───────────────────────
            Positioned(top: 0, left: 0, right: 0,
              child: Container(height: 380,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
            // ── Decorative blobs ───────────────────────────────
            Positioned(top: -20, right: -40,
              child: _blob(180, const Color(0xFF1976D2), 0.09),
            ),
            Positioned(bottom: 80, left: -50,
              child: _blob(160, const Color(0xFF00796B), 0.07),
            ),

            SafeArea(
              child: Column(children: [
                const SizedBox(height: 32),

                // ── Logo — perfectly visible, no glow/shadow ──
                // Just a clean rounded square with a white border
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    // Crisp white border makes logo pop on any bg
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(children: [
                      Image.asset('assets/logo.png',
                          width: 96, height: 96, fit: BoxFit.cover),
                      // Glossy sheen — top half only
                      Positioned(top: 0, left: 0, right: 0,
                        child: Container(height: 48,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.32),
                                Colors.white.withValues(alpha: 0.00),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 14),

                // App name — dark navy on light background
                const Text('UniTools',
                  style: TextStyle(
                    color: Color(0xFF0A1628),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                const Text('All-in-one calculator suite',
                  style: TextStyle(
                    color: Color(0xFF0A1628),
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Version badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF1976D2).withValues(alpha: 0.30),
                        width: 1),
                  ),
                  child: const Text(_version,
                    style: TextStyle(
                      color: Color(0xFF1565C0), // dark blue on light bg
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Cards list ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      itemCount: apps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) => _MenuCard(app: apps[i]),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 6),
                  child: Text('Tap any card to open',
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.50),
                      fontSize: 12,
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget _blob(double size, Color color, double opacity) =>
      Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: opacity), Colors.transparent,
          ]),
        ),
      );
}

// ── Data class ────────────────────────────────────────────────
class _AppItem {
  final int number;
  final String title, subtitle;
  final IconData icon;
  final Color g1, g2;
  final Widget screen;
  const _AppItem({required this.number, required this.title,
    required this.subtitle, required this.icon, required this.g1,
    required this.g2, required this.screen});
}

// ── Card widget ───────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final _AppItem app;
  const _MenuCard({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => app.screen));
      },
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [app.g1, app.g2],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(color: app.g1.withValues(alpha: 0.40),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(children: [
            // Glossy sheen
            Positioned(top: 0, left: 0, right: 0,
              child: Container(height: 41,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                // Number badge
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.50)),
                  ),
                  alignment: Alignment.center,
                  child: Text('${app.number}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 12),
                // Icon box
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.40)),
                  ),
                  alignment: Alignment.center,
                  child: Icon(app.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                // Title & subtitle — always white on coloured card bg
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.title,
                          style: const TextStyle(
                              color: Colors.white, // white always readable on gradient
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(app.subtitle,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.75), size: 14),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}