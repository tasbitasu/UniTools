import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../db/db_helper.dart';
import '../widgets/history_sheet.dart';

class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});
  @override
  State<ScientificCalculatorScreen> createState() =>
      _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState
    extends State<ScientificCalculatorScreen> {
  String _expression = '';
  String _current    = '0';
  double _accumulator = 0;
  String _pendingOp  = '';
  bool   _newNumber  = true;
  bool   _justEquals = false;
  bool   _isDeg      = true;
  bool   _showInverse = false;

  static const Color _purple     = Color(0xFF9D4EDD);
  static const Color _darkPurple = Color(0xFF7B2FBE);
  static const Color _numColor   = Color(0xFF2D2D3A);
  static const Color _fnColor    = Color(0xFF3A3A4A);
  static const Color _acColor    = Color(0xFFAA3333);

  double _toRad(double d) => _isDeg ? d * pi / 180 : d;
  double _toDeg(double r) => _isDeg ? r * 180 / pi : r;

  String _fmt(double val) {
    if (val.isNaN)      return 'Error';
    if (val.isInfinite) return val > 0 ? '∞' : '-∞';
    if (val == val.truncateToDouble() && val.abs() < 1e12)
      return val.toInt().toString();
    String s = val.toStringAsPrecision(10);
    if (s.contains('.'))
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  void _digit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_newNumber || _justEquals) {
        _current = d; _newNumber = false; _justEquals = false;
      } else {
        if (_current.length >= 12) return;
        _current = (_current == '0') ? d : _current + d;
      }
    });
  }

  void _dot() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_newNumber || _justEquals) {
        _current = '0.'; _newNumber = false; _justEquals = false;
      } else if (!_current.contains('.')) {
        _current += '.';
      }
    });
  }

  void _op(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      double val = double.tryParse(_current) ?? 0;
      if (_pendingOp.isNotEmpty && !_newNumber) {
        double result = _applyOp(_accumulator, val, _pendingOp);
        _accumulator = result;
        _expression += ' ${_fmt(val)} $op';
        _current = _fmt(result);
      } else {
        _accumulator = val;
        _expression  = '${_fmt(val)} $op';
      }
      _pendingOp = op; _newNumber = true; _justEquals = false;
    });
  }

  void _equals() {
    if (_pendingOp.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      double val    = double.tryParse(_current) ?? 0;
      double result = _applyOp(_accumulator, val, _pendingOp);
      final expr    = '$_expression ${_fmt(val)} =';
      _expression   = expr;
      _current      = _fmt(result);
      DBHelper().insert(HistoryEntry(
        type: 'scientific', expression: expr,
        result: _fmt(result), timestamp: DateTime.now(),
      ));
      _accumulator = result;
      _pendingOp = ''; _newNumber = true; _justEquals = true;
    });
  }

  double _applyOp(double a, double b, String op) {
    switch (op) {
      case '+':  return a + b;
      case '−':  return a - b;
      case '×':  return a * b;
      case '÷':  return b == 0 ? double.nan : a / b;
      case 'xʸ': return pow(a, b).toDouble();
      case 'ʸ√': return b == 0 ? double.nan : pow(a, 1 / b).toDouble();
      default:   return b;
    }
  }

  void _sciFunc(String fn) {
    HapticFeedback.lightImpact();
    double val = double.tryParse(_current) ?? 0;
    double result;
    String label;

    switch (fn) {
      case 'sin':   result = sin(_toRad(val));  label = 'sin($val)';  break;
      case 'cos':   result = cos(_toRad(val));  label = 'cos($val)';  break;
      case 'tan':
        final rad    = _toRad(val);
        final cosVal = cos(rad);
        result = cosVal.abs() < 1e-10 ? double.nan : sin(rad) / cosVal;
        label  = 'tan($val)'; break;
      case 'sin⁻¹':
        result = (val < -1 || val > 1) ? double.nan : _toDeg(asin(val));
        label  = 'sin⁻¹($val)'; break;
      case 'cos⁻¹':
        result = (val < -1 || val > 1) ? double.nan : _toDeg(acos(val));
        label  = 'cos⁻¹($val)'; break;
      case 'tan⁻¹': result = _toDeg(atan(val)); label = 'tan⁻¹($val)'; break;
      case 'log':
        result = val <= 0 ? double.nan : log(val) / ln10;
        label  = 'log($val)'; break;
      case 'ln':
        result = val <= 0 ? double.nan : log(val);
        label  = 'ln($val)'; break;
      case 'log₂':
        result = val <= 0 ? double.nan : log(val) / log(2);
        label  = 'log₂($val)'; break;
      case '√':
        result = val < 0 ? double.nan : sqrt(val);
        label  = '√($val)'; break;
      case '∛':  result = pow(val, 1/3).toDouble(); label = '∛($val)'; break;
      case 'x²': result = val * val;               label = '($val)²'; break;
      case 'x³': result = val * val * val;          label = '($val)³'; break;
      case '1/x':
        result = val == 0 ? double.nan : 1 / val;
        label  = '1/($val)'; break;
      case 'eˣ':  result = exp(val);                    label = 'e^($val)';  break;
      case '10ˣ': result = pow(10, val).toDouble();     label = '10^($val)'; break;
      case '2ˣ':  result = pow(2, val).toDouble();      label = '2^($val)';  break;
      case '|x|': result = val.abs();                   label = '|$val|';    break;
      case 'n!':
        if (val < 0 || val != val.truncateToDouble() || val > 20) {
          result = double.nan;
        } else {
          result = _fact(val.toInt()).toDouble();
        }
        label = '${val.toInt()}!'; break;
      case 'π':    result = pi;                    label = 'π';    break;
      case 'e':    result = e;                     label = 'e';    break;
      case 'Ran#': result = Random().nextDouble(); label = 'Ran#'; break;
      default: return;
    }

    if (result.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Math error: $label is undefined for this input'),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 2),
      ));
    }

    setState(() {
      _expression  = '$label =';
      _current     = _fmt(result);
      _justEquals  = true; _newNumber = true;
      _pendingOp   = ''; _accumulator = result;
    });
  }

  num _fact(int n) {
    if (n <= 1) return 1;
    num r = 1;
    for (int i = 2; i <= n; i++) r *= i;
    return r;
  }

  void _toggleSign() {
    HapticFeedback.selectionClick();
    setState(() {
      double v = double.tryParse(_current) ?? 0;
      if (v == 0) return;
      _current = _fmt(-v);
    });
  }

  void _percent() {
    HapticFeedback.selectionClick();
    setState(() {
      double val    = double.tryParse(_current) ?? 0;
      double result = _pendingOp.isNotEmpty ? _accumulator * val / 100 : val / 100;
      _current  = _fmt(result);
      _newNumber = true;
    });
  }

  void _ac() {
    HapticFeedback.heavyImpact();
    setState(() {
      _current = '0'; _expression = '';
      _accumulator = 0; _pendingOp = '';
      _newNumber = true; _justEquals = false;
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_justEquals || _newNumber) { _ac(); return; }
      if (_current.length <= 1 || _current == 'Error') {
        _current = '0';
      } else {
        _current = _current.substring(0, _current.length - 1);
        if (_current == '-') _current = '0';
      }
    });
  }

  void _openHistory() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: const HistorySheet(type: 'scientific', accent: _purple),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sciH = 36.0;
    final stdH = (size.height * 0.40) / 5 - 8;

    final row1 = _showInverse
        ? ['sin⁻¹', 'cos⁻¹', 'tan⁻¹', 'log₂', '2ˣ']
        : ['sin',   'cos',   'tan',   'log',  'ln'];
    final row2 = _showInverse
        ? ['∛',  'x²', 'x³', '1/x', '|x|']
        : ['√',  'x²', 'x³', '1/x', '|x|'];
    final row3 = _showInverse
        ? ['eˣ', '10ˣ', 'Ran#', 'π', 'e']
        : ['eˣ', '10ˣ', 'n!',   'π', 'e'];

    return Scaffold(
      body: Container(
        // Glossy deep-purple gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0012),
              Color(0xFF110020),
              Color(0xFF1A0A2E),
              Color(0xFF0D0820),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Gloss sheen at top
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded,
                              color: Colors.white60, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Scientific Calculator',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16, fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isDeg = !_isDeg);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _purple.withValues(alpha: 0.6)),
                            ),
                            child: Text(_isDeg ? 'DEG' : 'RAD',
                              style: const TextStyle(
                                color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.history_rounded,
                              color: Colors.white60, size: 22),
                          onPressed: _openHistory,
                        ),
                      ],
                    ),
                  ),

                  // ── Display ────────────────────────────────────
                  GestureDetector(
                    onLongPress: () {
                      if (_current != '0' && _current != 'Error') {
                        Clipboard.setData(ClipboardData(text: _current));
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
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.50),
                            const Color(0xFF1A1A2E).withValues(alpha: 0.80),
                          ],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _purple.withValues(alpha: 0.28), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: _purple.withValues(alpha: 0.10),
                            blurRadius: 20, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal, reverse: true,
                            child: Text(
                              _expression.isEmpty ? ' ' : _expression,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40),
                                fontSize: 14, fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _current,
                              style: TextStyle(
                                color: _current == 'Error'
                                    ? Colors.redAccent : Colors.white,
                                fontSize: 50, fontWeight: FontWeight.w200,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Scientific function rows ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _showInverse = !_showInverse);
                                },
                                child: Container(
                                  height: sciH,
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    gradient: _showInverse
                                        ? const LinearGradient(
                                            colors: [_darkPurple, _purple])
                                        : null,
                                    color: _showInverse ? null : _fnColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _purple.withValues(alpha: 0.50)),
                                    boxShadow: _showInverse
                                        ? [BoxShadow(
                                            color: _purple.withValues(alpha: 0.40),
                                            blurRadius: 8)]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('INV',
                                    style: TextStyle(
                                      color: _showInverse
                                          ? Colors.white
                                          : const Color(0xFFCE93D8),
                                      fontSize: 12, fontWeight: FontWeight.bold,
                                    )),
                                ),
                              ),
                            ),
                            Expanded(child: _sciBtn('xʸ', () => _op('xʸ'))),
                            Expanded(child: _sciBtn('ʸ√', () => _op('ʸ√'))),
                            Expanded(child: _sciBtn('%',  _percent)),
                            Expanded(child: _sciBtn('|x|', () => _sciFunc('|x|'))),
                          ],
                        ),
                        _sciRow(row1),
                        _sciRow(row2),
                        _sciRow(row3),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Standard numpad ────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _stdRow(stdH, [
                            _SB('AC',  _ac,          _acColor),
                            _SB('+/-', _toggleSign,  const Color(0xFF636366)),
                            _SB('⌫',   _backspace,   const Color(0xFF636366), isIcon: true),
                            _SB('÷',   () => _op('÷'), _purple,
                                active: _pendingOp == '÷' && _newNumber),
                          ]),
                          _stdRow(stdH, [
                            _SB('7', () => _digit('7'), _numColor),
                            _SB('8', () => _digit('8'), _numColor),
                            _SB('9', () => _digit('9'), _numColor),
                            _SB('×', () => _op('×'),   _purple,
                                active: _pendingOp == '×' && _newNumber),
                          ]),
                          _stdRow(stdH, [
                            _SB('4', () => _digit('4'), _numColor),
                            _SB('5', () => _digit('5'), _numColor),
                            _SB('6', () => _digit('6'), _numColor),
                            _SB('−', () => _op('−'),   _purple,
                                active: _pendingOp == '−' && _newNumber),
                          ]),
                          _stdRow(stdH, [
                            _SB('1', () => _digit('1'), _numColor),
                            _SB('2', () => _digit('2'), _numColor),
                            _SB('3', () => _digit('3'), _numColor),
                            _SB('+', () => _op('+'),   _purple,
                                active: _pendingOp == '+' && _newNumber),
                          ]),
                          // Bottom row: 0 (wide), . , =
                          SizedBox(
                            height: stdH + 4,
                            child: Row(children: [
                              Expanded(flex: 2, child: _pad(GestureDetector(
                                onTap: () => _digit('0'),
                                child: _cell(stdH, _numColor,
                                    const Text('0', style: TextStyle(
                                        color: Colors.white, fontSize: 22))),
                              ))),
                              Expanded(child: _pad(GestureDetector(
                                onTap: _dot,
                                child: _cell(stdH, _numColor,
                                    const Text('.', style: TextStyle(
                                        color: Colors.white, fontSize: 26))),
                              ))),
                              Expanded(child: _pad(GestureDetector(
                                onTap: _equals,
                                child: Container(
                                  height: stdH,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [_darkPurple, _purple],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(stdH / 2),
                                    boxShadow: [BoxShadow(
                                      color: _purple.withValues(alpha: 0.55),
                                      blurRadius: 14, offset: const Offset(0, 4),
                                    )],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text('=', style: TextStyle(
                                      color: Colors.white, fontSize: 24,
                                      fontWeight: FontWeight.w400)),
                                ),
                              ))),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ], // Column children
              ), // Column
            ), // SafeArea
          ], // Stack children
        ), // Stack
      ), // Container
    ); // Scaffold
  }

  // ── helper widgets ──────────────────────────────────────────

  Widget _sciRow(List<String> fns) => Row(
    children: fns.map((fn) =>
        Expanded(child: _sciBtn(fn, () => _sciFunc(fn)))).toList(),
  );

  Widget _sciBtn(String fn, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _fnColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _purple.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 4, offset: const Offset(0, 2),
        )],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(fn, style: const TextStyle(
            color: Color(0xFFCE93D8), fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    ),
  );

  Widget _stdRow(double h, List<_SB> btns) => SizedBox(
    height: h + 4,
    child: Row(
      children: btns.map((b) {
        final bool active = b.active;
        return Expanded(child: _pad(GestureDetector(
          onTap: b.onTap,
          child: Container(
            height: h,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [_darkPurple, _purple],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: active ? null : b.bg,
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: [BoxShadow(
                color: active
                    ? _purple.withValues(alpha: 0.40)
                    : Colors.black.withValues(alpha: 0.25),
                blurRadius: active ? 12 : 4,
                offset: const Offset(0, 2),
              )],
            ),
            alignment: Alignment.center,
            child: b.isIcon
                ? const Icon(Icons.backspace_outlined,
                    color: Colors.white, size: 18)
                : Text(b.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: b.label.length > 2 ? 13 : 20,
                      fontWeight: FontWeight.w400,
                    )),
          ),
        )));
      }).toList(),
    ),
  );

  Widget _cell(double h, Color color, Widget child) => Container(
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(h / 2),
      boxShadow: [BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 4, offset: const Offset(0, 2),
      )],
    ),
    alignment: Alignment.center,
    child: child,
  );

  Widget _pad(Widget w) =>
      Padding(padding: const EdgeInsets.all(3), child: w);
}

class _SB {
  final String label;
  final VoidCallback onTap;
  final Color bg;
  final bool active, isIcon;
  const _SB(this.label, this.onTap, this.bg,
      {this.active = false, this.isIcon = false});
}
