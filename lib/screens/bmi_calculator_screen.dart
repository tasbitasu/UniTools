import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/db_helper.dart';
import '../widgets/history_sheet.dart';

class BmiCalculatorScreen extends StatefulWidget {
  const BmiCalculatorScreen({super.key});
  @override
  State<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends State<BmiCalculatorScreen>
    with SingleTickerProviderStateMixin {

  final _weightCtrl   = TextEditingController();
  final _feetCtrl     = TextEditingController();
  final _inchCtrl     = TextEditingController();
  final _heightCtrl   = TextEditingController(); // for cm / m modes

  String _weightUnit = 'Kilogram (kg)';
  String _heightUnit = 'Foot (ft) + Inch (in)'; // default

  // No standalone 'Foot (ft)' option
  static const _weightUnits = ['Kilogram (kg)', 'Pound (lbs)'];
  static const _heightUnits = ['Foot (ft) + Inch (in)', 'Centimeter (cm)', 'Meter (m)'];

  double _bmi = 0;
  String _status = '';
  Color  _statusColor = Colors.transparent;
  bool   _hasResult = false;

  // Validation flags
  bool _weightErr = false;
  bool _feetErr   = false;
  bool _inchErr   = false;
  bool _cmErr     = false;

  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  static const Color _accent  = Color(0xFF4DB6AC);
  static const Color _accDk   = Color(0xFF00897B);

  bool get _isFtIn => _heightUnit == 'Foot (ft) + Inch (in)';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _weightCtrl.dispose(); _feetCtrl.dispose();
    _inchCtrl.dispose();   _heightCtrl.dispose();
    super.dispose();
  }

  // ── Unit conversions ─────────────────────────────────────────

  /// Weight → kg
  double _toKg(double v) =>
      _weightUnit == 'Pound (lbs)' ? v * 0.45359237 : v;

  /// Height → metres  (accurate)
  double _toMetres() {
    if (_isFtIn) {
      final ft  = double.tryParse(_feetCtrl.text.trim()) ?? 0.0;
      final inc = double.tryParse(_inchCtrl.text.trim()) ?? 0.0;
      return (ft * 12.0 + inc) * 0.0254;
    }
    final h = double.tryParse(_heightCtrl.text.trim()) ?? 0.0;
    return _heightUnit == 'Centimeter (cm)' ? h / 100.0 : h;
  }

  // ── Calculate ────────────────────────────────────────────────

  void _calculate() {
    HapticFeedback.mediumImpact();
    _clearErrors();

    final wt = _weightCtrl.text.trim();

    // Validate weight
    if (wt.isEmpty) {
      setState(() => _weightErr = true);
      _showError('Please enter your weight'); return;
    }
    final double? wRaw = double.tryParse(wt);
    if (wRaw == null || wRaw <= 0) {
      setState(() => _weightErr = true);
      _showError('Weight must be a positive number'); return;
    }

    // Validate height (ft+in: BOTH mandatory)
    if (_isFtIn) {
      final ftTxt  = _feetCtrl.text.trim();
      final inTxt  = _inchCtrl.text.trim();

      if (ftTxt.isEmpty || inTxt.isEmpty) {
        setState(() {
          _feetErr = ftTxt.isEmpty;
          _inchErr = inTxt.isEmpty;
        });
        _showError('Both Feet and Inches are required'); return;
      }

      final double? ft  = double.tryParse(ftTxt);
      final double? inc = double.tryParse(inTxt);

      if (ft == null || ft < 0) {
        setState(() => _feetErr = true);
        _showError('Enter a valid feet value (≥ 0)'); return;
      }
      if (inc == null || inc < 0 || inc >= 12) {
        setState(() => _inchErr = true);
        _showError('Inches must be 0 – 11'); return;
      }
      // Must have at least some height
      if (ft == 0 && inc == 0) {
        setState(() { _feetErr = true; _inchErr = true; });
        _showError('Height cannot be zero'); return;
      }
    } else {
      final htTxt = _heightCtrl.text.trim();
      if (htTxt.isEmpty) {
        setState(() => _cmErr = true);
        _showError('Please enter your height'); return;
      }
      final double? h = double.tryParse(htTxt);
      if (h == null || h <= 0) {
        setState(() => _cmErr = true);
        _showError('Height must be a positive number'); return;
      }
    }

    // ── Compute ─────────────────────────────────────────────
    final double kg      = _toKg(wRaw);
    final double hMetres = _toMetres();

    if (hMetres <= 0) {
      _showError('Height must be greater than zero'); return;
    }

    final double bmi = kg / (hMetres * hMetres);

    String status; Color color;
    if      (bmi < 18.5) { status = 'Underweight';     color = Colors.blue.shade300; }
    else if (bmi < 25.0) { status = 'Normal weight ✓'; color = Colors.greenAccent; }
    else if (bmi < 30.0) { status = 'Overweight';      color = Colors.orangeAccent; }
    else                 { status = 'Obese';            color = Colors.redAccent; }

    final String hLabel = _isFtIn
        ? '${_feetCtrl.text} ft ${_inchCtrl.text} in'
        : '${_heightCtrl.text} $_heightUnit';

    DBHelper().insert(HistoryEntry(
      type: 'bmi',
      expression: '${_weightCtrl.text} $_weightUnit / $hLabel',
      result: 'BMI ${bmi.toStringAsFixed(1)} – $status',
      timestamp: DateTime.now(),
    ));

    setState(() {
      _bmi = bmi; _status = status; _statusColor = color;
      _hasResult = true;
    });
    _animCtrl.forward(from: 0);
  }

  void _clearErrors() => setState(() {
    _weightErr = false; _feetErr = false;
    _inchErr   = false; _cmErr   = false;
  });

  void _reset() {
    HapticFeedback.lightImpact();
    setState(() {
      _weightCtrl.clear(); _feetCtrl.clear();
      _inchCtrl.clear();   _heightCtrl.clear();
      _bmi = 0; _status = ''; _hasResult = false;
    });
    _clearErrors();
    _animCtrl.reset();
  }

  void _showError(String msg) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1E2D2D),
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
        child: const HistorySheet(type: 'bmi', accent: _accent),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0C1E1E), Color(0xFF003A33), Color(0xFF00695C)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(children: [
          // Glossy top sheen
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 240,
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
            // ── AppBar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('BMI Calculator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, // white on dark teal ✓
                      fontSize: 16, fontWeight: FontWeight.w700),
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

                // ── BMI circle — fixed position always ─────
                SizedBox(
                  height: 170,
                  child: Center(
                    child: _hasResult
                        ? ScaleTransition(scale: _scaleAnim, child: _bmiCircle())
                        : _placeholderCircle(),
                  ),
                ),

                if (_hasResult) ...[
                  const SizedBox(height: 10),
                  _statusBadge(),
                ],

                const SizedBox(height: 20),

                // ── Input card ──────────────────────────────
                _glassCard(child: Column(children: [
                  // Weight row
                  _inputField('Enter weight (e.g. 65)', _weightCtrl, _weightErr),
                  const SizedBox(height: 6),
                  _dropdown(_weightUnit, _weightUnits,
                      (v) => setState(() => _weightUnit = v!)),

                  const Divider(color: Colors.white12, height: 24),

                  // Height — ft+in shows TWO fields (both mandatory)
                  if (_isFtIn) ...[
                    Row(children: [
                      Expanded(
                        child: _inputField('Feet *', _feetCtrl, _feetErr),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _inputField('Inches * (0–11)', _inchCtrl, _inchErr),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('★ Both Feet and Inches are required',
                        style: TextStyle(
                          color: _accent.withValues(alpha: 0.70),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ] else ...[
                    _inputField(
                      _heightUnit == 'Centimeter (cm)'
                          ? 'Height in cm (e.g. 170)'
                          : 'Height in m (e.g. 1.70)',
                      _heightCtrl, _cmErr,
                    ),
                  ],

                  const SizedBox(height: 6),
                  _dropdown(_heightUnit, _heightUnits, (v) {
                    setState(() {
                      _heightUnit = v!;
                      _feetCtrl.clear(); _inchCtrl.clear();
                      _heightCtrl.clear();
                    });
                    _clearErrors();
                  }),
                ])),

                const SizedBox(height: 16),

                // ── BMI category legend ─────────────────────
                _glassCard(child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _legend('< 18.5',    'Under\nweight', Colors.blue.shade300),
                    _legend('18.5–24.9', 'Normal',        Colors.greenAccent),
                    _legend('25–29.9',   'Over\nweight',  Colors.orangeAccent),
                    _legend('≥ 30',      'Obese',         Colors.redAccent),
                  ],
                )),

                const SizedBox(height: 20),

                // ── Buttons — Calculate (teal) | Reset (RED) ─
                Row(children: [
                  Expanded(child: _btn(
                    'Calculate', Icons.calculate_rounded,
                    const LinearGradient(
                        colors: [Color(0xFF00695C), Color(0xFF4DB6AC)]),
                    _calculate,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _btn(
                    'Reset', Icons.refresh_rounded,
                    // RED gradient as requested
                    const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFFEF5350)]),
                    _reset,
                  )),
                ]),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }

  // ─── widget helpers ─────────────────────────────────────────

  Widget _bmiCircle() => Container(
    width: 155, height: 155,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [
        _statusColor.withValues(alpha: 0.20), Colors.transparent,
      ]),
      border: Border.all(color: _statusColor, width: 2.5),
      boxShadow: [
        BoxShadow(
          color: _statusColor.withValues(alpha: 0.45),
          blurRadius: 28, spreadRadius: 4,
        ),
        BoxShadow(
          color: _statusColor.withValues(alpha: 0.18),
          blurRadius: 55, spreadRadius: 8,
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_bmi.toStringAsFixed(1),
        style: const TextStyle(
            color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
      Text('BMI',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65), fontSize: 14)),
    ]),
  );

  Widget _placeholderCircle() => Container(
    width: 150, height: 150,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.05),
      border: Border.all(color: Colors.white24, width: 2),
      boxShadow: [BoxShadow(
        color: _accent.withValues(alpha: 0.14),
        blurRadius: 22, spreadRadius: 2,
      )],
    ),
    alignment: Alignment.center,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.monitor_weight_rounded, size: 44,
          color: Colors.white.withValues(alpha: 0.38)),
      const SizedBox(height: 4),
      Text('Enter data',
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
    ]),
  );

  Widget _statusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
    decoration: BoxDecoration(
      color: _statusColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: _statusColor, width: 1.5),
      boxShadow: [BoxShadow(
        color: _statusColor.withValues(alpha: 0.22), blurRadius: 10,
      )],
    ),
    child: Text(_status,
      style: TextStyle(
          color: _statusColor, fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18, offset: const Offset(0, 6),
          )],
        ),
        child: child,
      ),
    ),
  );

  /// Only bottom underline — NO top border / outline
  Widget _inputField(
      String hint, TextEditingController ctrl, bool err) =>
      TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
            color: Colors.white, // white on dark teal ✓
            fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.28), fontSize: 13),
          // Three properties together = bottom-only underline
          border: InputBorder.none,
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: err ? Colors.redAccent : Colors.white30, width: 1,
            ),
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

  /// Dropdown — same single-underline strategy
  Widget _dropdown(
      String val, List<String> items, ValueChanged<String?> onChange) =>
      DropdownButtonFormField<String>(
        value: val,
        isExpanded: true,
        dropdownColor: const Color(0xFF1A3A3A),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: items.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
        onChanged: onChange,
        decoration: const InputDecoration(
          isDense: true,
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

  Widget _legend(String range, String label, Color color) =>
      Column(children: [
        Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(range,
          style: const TextStyle(
              fontSize: 9, color: Colors.white70, fontWeight: FontWeight.bold)),
        Text(label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 8, color: Colors.white54)),
      ]);

  Widget _btn(String label, IconData icon, Gradient gradient,
      VoidCallback onTap) =>
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
                color: Colors.white,
                fontSize: 15, fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      );
}
