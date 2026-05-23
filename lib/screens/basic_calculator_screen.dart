import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/db_helper.dart';
import '../widgets/history_sheet.dart';

class BasicCalculatorScreen extends StatefulWidget {
  const BasicCalculatorScreen({super.key});
  @override
  State<BasicCalculatorScreen> createState() => _BasicCalculatorScreenState();
}

class _BasicCalculatorScreenState extends State<BasicCalculatorScreen> {
  String _expression = '';
  String _display    = '0';
  double _acc        = 0;
  String _op         = '';
  bool   _newNum     = true;
  bool   _afterEq    = false;

  // ─── Colours ──────────────────────────────────────────────
  static const Color _orange   = Color(0xFFFF9F0A);
  static const Color _orangeDk = Color(0xFFE65100);
  static const Color _grey     = Color(0xFF3A3A4A);
  static const Color _red      = Color(0xFFC62828);
  static const Color _num      = Color(0xFF1C1C2E);

  // ─── Core logic ───────────────────────────────────────────

  void _pressDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_newNum || _afterEq) {
        _display = d; _newNum = false; _afterEq = false;
      } else {
        if (_display.length >= 15) return;
        _display = (_display == '0') ? d : _display + d;
      }
    });
  }

  void _pressDot() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_newNum || _afterEq) {
        _display = '0.'; _newNum = false; _afterEq = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _pressOp(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      final double val = double.tryParse(_display) ?? 0;
      if (_op.isNotEmpty && !_newNum) {
        // Chain operations — compute previous before storing new op
        final double result = _applyOp(_acc, val);
        _acc        = result;
        _expression = '${_expression} ${_fmt(val)} $op';
        _display    = _fmt(result);
      } else {
        _acc        = val;
        _expression = '${_fmt(val)} $op';
      }
      _op = op; _newNum = true; _afterEq = false;
    });
  }

  void _pressEquals() {
    if (_op.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final double val    = double.tryParse(_display) ?? 0;
      final double result = _applyOp(_acc, val);
      final String expr   = '$_expression ${_fmt(val)} =';
      _expression = expr;
      _display    = _fmt(result);
      DBHelper().insert(HistoryEntry(
        type: 'basic', expression: expr,
        result: _fmt(result), timestamp: DateTime.now(),
      ));
      _acc = result; _op = ''; _newNum = true; _afterEq = true;
    });
  }

  double _applyOp(double a, double b) {
    switch (_op) {
      case '+': return a + b;
      case '−': return a - b;
      case '×': return a * b;
      case '÷': return b == 0 ? double.nan : a / b;
      default:  return b;
    }
  }

  void _pressPercent() {
    HapticFeedback.selectionClick();
    setState(() {
      final double val = double.tryParse(_display) ?? 0;
      // If there's a pending op, percent is relative to accumulator
      final double result =
          _op.isNotEmpty ? _acc * val / 100.0 : val / 100.0;
      _display = _fmt(result);
      _newNum  = true;
    });
  }

  void _pressToggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      final double val = double.tryParse(_display) ?? 0;
      if (val == 0) return;
      _display = _fmt(-val);
    });
  }

  void _pressAC() {
    HapticFeedback.heavyImpact();
    setState(() {
      _display = '0'; _expression = '';
      _acc = 0; _op = ''; _newNum = true; _afterEq = false;
    });
  }

  void _pressBack() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_afterEq || _newNum) { _pressAC(); return; }
      if (_display.length <= 1 || _display == 'Error') {
        _display = '0';
      } else {
        _display = _display.substring(0, _display.length - 1);
        if (_display == '-' || _display == '') _display = '0';
      }
    });
  }

  /// Format a double cleanly — no trailing .0 for integers, up to 10 sig figs
  String _fmt(double v) {
    if (v.isNaN)      return 'Error';
    if (v.isInfinite) return v > 0 ? '∞' : '-∞';
    if (v == v.truncateToDouble() && v.abs() < 1e13)
      return v.toInt().toString();
    String s = v.toStringAsPrecision(10);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  void _openHistory() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: const HistorySheet(type: 'basic', accent: _orange),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final padTop  = MediaQuery.of(context).padding.top;
    final btnH    = ((size.height - padTop) * 0.53) / 5 - 10;

    return Scaffold(
      body: Container(
        // Warm dark orange-brown gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF100800),
              Color(0xFF1C1000),
              Color(0xFF251500),
              Color(0xFF1A0F00),
            ],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(children: [
          Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(child: Column(children: [

            // ── AppBar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Basic Calculator',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, // white on dark ✓
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

            // ── Display ─────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onLongPress: () {
                  if (_display != '0' && _display != 'Error') {
                    Clipboard.setData(ClipboardData(text: _display));
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    // Subtle glass surface on dark bg
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    // Border: warm amber at LOW opacity — visible but not garish
                    border: Border.all(
                      color: _orange.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      // Warm inner glow — subtle
                      BoxShadow(
                        color: _orange.withValues(alpha: 0.06),
                        blurRadius: 22, spreadRadius: 2,
                      ),
                      // Depth shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14, offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal, reverse: true,
                        child: Text(
                          _expression.isEmpty ? ' ' : _expression,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.42),
                            fontSize: 18, fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _display,
                          style: TextStyle(
                            color: _display == 'Error'
                                ? Colors.redAccent
                                : Colors.white, // white on dark ✓
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(right: 18, bottom: 4),
              child: Text('long press to copy',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.18), fontSize: 11)),
            ),

            // ── Button grid ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              child: Column(children: [
                _row(btnH, [
                  _B('AC', _pressAC,              _red),
                  _B('⌫',  _pressBack,            _grey, isIcon: true),
                  _B('%',  _pressPercent,         _grey),
                  _B('÷',  () => _pressOp('÷'),  _orange,
                      isOp: true, active: _op == '÷' && _newNum),
                ]),
                _row(btnH, [
                  _B('7', () => _pressDigit('7'), _num),
                  _B('8', () => _pressDigit('8'), _num),
                  _B('9', () => _pressDigit('9'), _num),
                  _B('×', () => _pressOp('×'),   _orange,
                      isOp: true, active: _op == '×' && _newNum),
                ]),
                _row(btnH, [
                  _B('4', () => _pressDigit('4'), _num),
                  _B('5', () => _pressDigit('5'), _num),
                  _B('6', () => _pressDigit('6'), _num),
                  _B('−', () => _pressOp('−'),   _orange,
                      isOp: true, active: _op == '−' && _newNum),
                ]),
                _row(btnH, [
                  _B('1', () => _pressDigit('1'), _num),
                  _B('2', () => _pressDigit('2'), _num),
                  _B('3', () => _pressDigit('3'), _num),
                  _B('+', () => _pressOp('+'),   _orange,
                      isOp: true, active: _op == '+' && _newNum),
                ]),
                _row(btnH, [
                  _B('+/-', _pressToggleSign, _grey),
                  _B('0',   () => _pressDigit('0'), _num),
                  _B('.',   _pressDot,              _num),
                  _B('=',   _pressEquals,           _orange, isEq: true),
                ]),
              ]),
            ),
          ])),
        ]),
      ),
    );
  }

  Widget _row(double h, List<_B> btns) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: btns.map((b) {
      final bool lit = b.active;
      return Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GestureDetector(
          onTap: b.onTap,
          child: b.isEq
              ? _eqBtn(h)
              : Container(
                  height: h,
                  decoration: BoxDecoration(
                    gradient: lit
                        ? const LinearGradient(
                            colors: [_orangeDk, _orange],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: lit ? null : b.bg,
                    borderRadius: BorderRadius.circular(h / 2),
                    // Very subtle border adds depth
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 0.8),
                    boxShadow: [BoxShadow(
                      color: lit
                          ? _orange.withValues(alpha: 0.38)
                          : Colors.black.withValues(alpha: 0.28),
                      blurRadius: lit ? 12 : 4,
                      offset: const Offset(0, 3),
                    )],
                  ),
                  alignment: Alignment.center,
                  child: b.isIcon
                      ? const Icon(Icons.backspace_outlined,
                          color: Colors.white, size: 22)
                      : Text(b.label,
                          style: TextStyle(
                            color: Colors.white, // always white on dark buttons ✓
                            fontSize: b.label.length > 2 ? 15 : 26,
                            fontWeight: FontWeight.w400,
                          )),
                ),
        ),
      ));
    }).toList()),
  );

  Widget _eqBtn(double h) => Container(
    height: h,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_orangeDk, _orange],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(h / 2),
      boxShadow: [BoxShadow(
        color: _orange.withValues(alpha: 0.50),
        blurRadius: 14, offset: const Offset(0, 5),
      )],
    ),
    alignment: Alignment.center,
    child: const Text('=',
      style: TextStyle(color: Colors.white, fontSize: 28)),
  );
}

class _B {
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final bool isOp, active, isIcon, isEq;
  const _B(this.label, this.onTap, this.bg,
      {this.isOp = false, this.active = false,
       this.isIcon = false, this.isEq = false});
}
