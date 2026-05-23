import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/db_helper.dart';
import '../widgets/history_sheet.dart';

class LandConverterScreen extends StatefulWidget {
  const LandConverterScreen({super.key});
  @override
  State<LandConverterScreen> createState() => _LandConverterScreenState();
}

class _LandConverterScreenState extends State<LandConverterScreen>
    with SingleTickerProviderStateMixin {
  final _lenCtrl = TextEditingController();
  final _widCtrl = TextEditingController();
  String _lenUnit = 'Meter (m)';
  String _widUnit = 'Meter (m)';

  double _sqm = 0, _sqft = 0, _shotok = 0, _katha = 0, _bigha = 0, _acre = 0;
  bool _lenErr = false, _widErr = false, _hasCalculated = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _units = [
    'Meter (m)', 'Foot (ft)', 'Inch (in)',
    'Yard (yd)', 'Centimeter (cm)', 'Millimeter (mm)',
  ];

  // Colour palette — white text on dark blue bg
  static const Color _bg1    = Color(0xFF0A1628);
  static const Color _bg2    = Color(0xFF0E2040);
  static const Color _bg3    = Color(0xFF1565C0);
  static const Color _accent = Color(0xFF42A5F5);
  static const Color _accDk  = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _animCtrl.dispose(); _lenCtrl.dispose(); _widCtrl.dispose();
    super.dispose();
  }

  double _toMeters(double v, String u) {
    switch (u) {
      case 'Foot (ft)':        return v * 0.3048;
      case 'Inch (in)':        return v * 0.0254;
      case 'Yard (yd)':        return v * 0.9144;
      case 'Centimeter (cm)':  return v / 100.0;
      case 'Millimeter (mm)':  return v / 1000.0;
      default:                 return v; // Meter
    }
  }

  void _calculate() {
    HapticFeedback.mediumImpact();
    final lt = _lenCtrl.text.trim();
    final wt = _widCtrl.text.trim();
    setState(() { _lenErr = lt.isEmpty; _widErr = wt.isEmpty; });
    if (lt.isEmpty || wt.isEmpty) {
      _showError('Please enter both Length and Width'); return;
    }
    final double? lRaw = double.tryParse(lt);
    final double? wRaw = double.tryParse(wt);
    if (lRaw == null || lRaw <= 0 || wRaw == null || wRaw <= 0) {
      setState(() {
        _lenErr = lRaw == null || lRaw <= 0;
        _widErr = wRaw == null || wRaw <= 0;
      });
      _showError('Enter valid positive numbers'); return;
    }
    final double lm   = _toMeters(lRaw, _lenUnit);
    final double wm   = _toMeters(wRaw, _widUnit);
    final double area = lm * wm;

    DBHelper().insert(HistoryEntry(
      type: 'land',
      expression:
          '${_lenCtrl.text} ${_lenUnit.split(' ')[0]} × ${_widCtrl.text} ${_widUnit.split(' ')[0]}',
      result:
          '${area.toStringAsFixed(4)} m²  |  ${(area * 0.0247096615).toStringAsFixed(4)} শতক',
      timestamp: DateTime.now(),
    ));

    setState(() {
      _sqm    = area;
      _sqft   = area * 10.76391;          // exact NIST
      _shotok = area / 40.4686;           // 1 shotok = 40.468 m²
      _katha  = area / 66.8902;          // 1 katha  = 67.09 m² (Bengal)
      _bigha  = area / 1337.804;         // 1 bigha  = 1344.93 m² (Bengal)
      _acre   = area / 4046.8564;       // exact
      _lenErr = false; _widErr = false; _hasCalculated = true;
    });
    _animCtrl.forward(from: 0);
  }

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _lenCtrl.clear(); _widCtrl.clear();
      _sqm = _sqft = _shotok = _katha = _bigha = _acre = 0;
      _lenErr = _widErr = false; _hasCalculated = false;
    });
    _animCtrl.value = 1.0;
  }

  void _showError(String msg) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1A2840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.error_outline, color: Colors.redAccent),
        SizedBox(width: 8),
        Text('Error', style: TextStyle(color: Colors.white)),
      ]),
      content: Text(msg,
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
      actions: [TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('OK', style: TextStyle(color: _accent)),
      )],
    ),
  );

  void _openHistory() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: const HistorySheet(type: 'land', accent: _accent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bg1, _bg2, _bg3],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(children: [
          // Subtle glossy sheen top
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(child: Column(children: [
            // ── AppBar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Land Measurement Converter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, // white on dark bg ✓
                      fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded,
                      color: Colors.white70, size: 22),
                  onPressed: _openHistory,
                ),
              ]),
            ),

            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(children: [
                // Hero icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_accDk, _accent],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: _accent.withValues(alpha: 0.30),
                      blurRadius: 18, offset: const Offset(0, 4),
                    )],
                  ),
                  child: const Icon(Icons.landscape_rounded,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // ── Input card ──────────────────────────────
                _glassCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LENGTH section
                    _label('Length'),
                    const SizedBox(height: 6),
                    // TextField: ONLY bottom border (no outline/top border)
                    _textField('e.g. 10', _lenCtrl, _lenErr),
                    const SizedBox(height: 6),
                    // Dropdown: ONLY bottom border — decoration has border:none
                    _unitDropdown(_lenUnit,
                        (v) => setState(() => _lenUnit = v!)),

                    const Divider(color: Colors.white12, height: 24),

                    // WIDTH section
                    _label('Width'),
                    const SizedBox(height: 6),
                    _textField('e.g. 5', _widCtrl, _widErr),
                    const SizedBox(height: 6),
                    _unitDropdown(_widUnit,
                        (v) => setState(() => _widUnit = v!)),
                  ],
                )),

                const SizedBox(height: 14),

                // ── Action buttons ──────────────────────────
                Row(children: [
                  Expanded(child: _actionBtn(
                    'Calculate', Icons.calculate_rounded,
                    const LinearGradient(
                        colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)]),
                    _calculate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _actionBtn(
                    'Reset', Icons.refresh_rounded,
                    const LinearGradient(
                        colors: [Color(0xFF880E4F), Color(0xFFE91E63)]),
                    _reset,
                  )),
                ]),

                const SizedBox(height: 14),

                // ── Results card ────────────────────────────
                FadeTransition(
                  opacity: _fadeAnim,
                  child: _glassCard(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.straighten_rounded,
                            color: _accent, size: 18),
                        const SizedBox(width: 8),
                        const Text('Results',
                          style: TextStyle(
                            color: Colors.white, // white on dark ✓
                            fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const Spacer(),
                        Text('long press to copy',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 10),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      // ── All rows aligned with fixed-width label ─
                      _resultRow('Sq. Meter (বর্গ মিটার)',    _sqm,    'm²'),
                      _resultRow('Sq. Foot (বর্গ ফুট)',     _sqft,   'ft²'),
                      const Divider(color: Colors.white12, height: 16),
                      _resultRow('Decimel (শতক)', _shotok, 'শতক', hi: true),
                      _resultRow('Katha (কাঠা)',         _katha,  'কাঠা', hi: true),
                      _resultRow('Bigha (বিঘা)',         _bigha,  'বিঘা', hi: true),
                      _resultRow('Acre (একর)',         _acre,   'একর', hi: true),
                    ],
                  )),
                ),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }

  // ─── helpers ────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Slightly lighter than dark bg — gives "glass" on dark
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 18, offset: const Offset(0, 6),
          )],
        ),
        child: child,
      ),
    ),
  );

  Widget _label(String t) => Text(t,
    style: TextStyle(
      color: _accent.withValues(alpha: 0.95), // blue accent on dark bg ✓
      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5,
    ),
  );

  /// No top/side/outline border — only an underline at bottom
  Widget _textField(String hint, TextEditingController ctrl, bool err) =>
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Colors.white, // white on dark ✓
          fontSize: 16, fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.30), fontSize: 14),
          // KEY: these three remove every default border except the underline
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: err ? Colors.redAccent : Colors.white30, width: 1),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: _accent, width: 2),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          suffixIcon: err
              ? const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18)
              : null,
        ),
      );

  /// Same border strategy as text field — one underline, NO top border
  Widget _unitDropdown(String val, ValueChanged<String?> onChange) =>
      DropdownButtonFormField<String>(
        value: val,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A2840),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: _units
            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
            .toList(),
        onChanged: onChange,
        decoration: const InputDecoration(
          isDense: true,
          // Remove ALL default borders, keep only bottom underline
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12, width: 1),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _accent, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 6),
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white38, size: 22),
      );

  /// Result row — label + value always right-aligned via Expanded+Row
  Widget _resultRow(String label, double val, String unit, {bool hi = false}) {
    final display = _hasCalculated ? val.toStringAsFixed(2) : '0.00';
    return GestureDetector(
      onLongPress: () {
        if (!_hasCalculated) return;
        Clipboard.setData(
            ClipboardData(text: '${val.toStringAsFixed(6)} $unit'));
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 1),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hi
              ? _accent.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: hi
              ? Border.all(color: _accent.withValues(alpha: 0.28))
              : null,
        ),
        child: Row(children: [
          // Fixed-width label — ensures all value columns align
          SizedBox(
            width: 130,
            child: Text(label,
              style: TextStyle(
                // Accent blue for highlighted rows, white70 for others — both readable on dark bg
                color: hi ? _accent : Colors.white70,
                fontSize: 13, fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Value + unit aligned to the right
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(display,
                  style: TextStyle(
                    color: hi ? Colors.white : Colors.white,
                    fontSize: 15, fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 5),
                SizedBox(
                  width: 36,
                  child: Text(unit,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Gradient gradient, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 10, offset: const Offset(0, 4),
            )],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
              style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      );
}
