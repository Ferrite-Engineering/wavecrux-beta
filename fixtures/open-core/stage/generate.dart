// Generates `stage_demo.vcd` — a hand-crafted waveform that exercises
// every Stage primitive and both built-in board widgets.
//
// Re-run with:   dart run test/fixtures/stage/generate.dart
//
// The output VCD lives next to this file. Signal names are chosen so
// the user can see at a glance which Stage widget each one drives:
//
//   top.primitives.led_*           → LED widget
//   top.primitives.toggle_*        → Toggle Switch widget
//   top.primitives.seven_seg_*     → Seven-Segment widget
//   top.primitives.bus_*           → Bus Readout widget
//   top.primitives.fsm_state       → State Indicator widget
//   top.primitives.level_*         → Level Bar widget
//   top.primitives.analog_*        → Signal Graph widget
//   top.basys3.{led,sw,btn,digit}* → Basys 3 board slots
//   top.de10.{ledr,sw,key,hex}*    → DE10-Lite board slots
//
// Timescale is 1 ns; the simulation runs 0..20 µs so every signal has
// many transitions visible while scrubbing the cursor.

import 'dart:io';
import 'dart:math' as math;

const int _simulationDurationNs = 20000;
const int _stepNs = 50;

void main() {
  final out = StringBuffer();
  final defs = _buildDefinitions();

  // ── header ──────────────────────────────────────────────────────────────
  out
    ..writeln(r'$date')
    ..writeln('  ${DateTime.now().toUtc().toIso8601String()}')
    ..writeln(r'$end')
    ..writeln(r'$version')
    ..writeln('  WaveCrux Stage demo waveform generator')
    ..writeln(r'$end')
    ..writeln(r'$comment')
    ..writeln('  Hand-crafted fixture — exercises every Stage primitive plus')
    ..writeln('  the Basys 3 and DE10-Lite board widgets. Re-generate with')
    ..writeln('  `dart run test/fixtures/stage/generate.dart`.')
    ..writeln(r'$end')
    ..writeln(r'$timescale 1 ns $end');

  // Hierarchical scope declarations.
  defs.scopeLines.forEach(out.writeln);
  out.writeln(r'$enddefinitions $end');

  // ── value changes ──────────────────────────────────────────────────────
  // Track each signal's last emitted value so we only write deltas.
  final last = <String, String>{};

  void emitChange(_Var v, num value, StringBuffer buf) {
    final encoded = v.encode(value);
    if (last[v.idcode] == encoded) return;
    last[v.idcode] = encoded;
    buf.writeln(encoded);
  }

  // Initial values: $dumpvars at t=0.
  out
    ..writeln('#0')
    ..writeln(r'$dumpvars');
  for (final v in defs.vars) {
    final initial = v.value(0);
    last[v.idcode] = v.encode(initial);
    out.writeln(last[v.idcode]);
  }
  out.writeln(r'$end');

  for (var t = _stepNs; t <= _simulationDurationNs; t += _stepNs) {
    final stepBuf = StringBuffer();
    for (final v in defs.vars) {
      emitChange(v, v.value(t), stepBuf);
    }
    if (stepBuf.isNotEmpty) {
      out
        ..writeln('#$t')
        ..write(stepBuf);
    }
  }

  final outFile = File('test/fixtures/stage/stage_demo.vcd')
    ..writeAsStringSync(out.toString());
  // Generator script — print the result to stdout so the operator can
  // see what was written. avoid_print is a runtime-app rule; not
  // applicable to one-shot tools.
  // ignore: avoid_print
  print(
    'Wrote ${outFile.path} (${outFile.lengthSync()} bytes, '
    '${defs.vars.length} signals).',
  );
}

// ── definitions ────────────────────────────────────────────────────────────

class _Definitions {
  _Definitions(this.scopeLines, this.vars);
  final List<String> scopeLines;
  final List<_Var> vars;
}

_Definitions _buildDefinitions() {
  final scopeLines = <String>[];
  final vars = <_Var>[];
  final ids = _IdCodeGenerator();

  void scope(String name) => scopeLines.add(
    r'$scope module '
    '$name'
    r' $end',
  );
  void upscope() => scopeLines.add(r'$upscope $end');

  void addVar(_Var v) {
    v.idcode = ids.next();
    vars.add(v);
    final kind = v.isReal ? 'real' : 'wire';
    final width = v.isReal ? 64 : v.bitWidth;
    scopeLines.add('\$var $kind $width ${v.idcode} ${v.name} \$end');
  }

  scope('top');

  // ── primitives ───────────────────────────────────────────────────────
  scope('primitives');
  // LED: fast and slow toggles.
  addVar(_Var.scalar('led_blink', _periodicScalar(periodNs: 200)));
  addVar(_Var.scalar('led_slow', _periodicScalar(periodNs: 1000)));
  // Toggles: medium and slow.
  addVar(_Var.scalar('toggle_a', _periodicScalar(periodNs: 600)));
  addVar(_Var.scalar('toggle_b', _periodicScalar(periodNs: 1500)));
  // Seven-segment value mode: 4-bit hex counter incrementing every
  // 250 ns (full 0..f cycle).
  addVar(_Var.bus('seven_seg_value', 4, _counter(stepNs: 250, modulo: 16)));
  // Seven-segment cathode mode: 7-bit cathode bus encoding the same
  // 0..f digit pattern as the value-mode signal. Bit 0 = a (top),
  // bit 6 = g (middle); active-high.
  addVar(
    _Var.bus('seven_seg_cathodes', 7, (t) {
      final digit = (t ~/ 250) % 16;
      return _hexCathodePattern(digit);
    }),
  );
  // Seven-segment decimal point: toggles every 1000 ns so users can
  // see the dp indicator move alongside cathode-mode digits.
  addVar(_Var.scalar('seven_seg_dp', _periodicScalar(periodNs: 1000)));
  // Bus readouts: 8 and 16 bit counters at different rates.
  addVar(_Var.bus('bus_byte', 8, _counter(stepNs: 100, modulo: 256)));
  addVar(
    _Var.bus('bus_word', 16, _counter(stepNs: 200, modulo: 65536)),
  );
  // FSM state: 0..6 cycling every 800 ns.
  addVar(_Var.bus('fsm_state', 3, _counter(stepNs: 800, modulo: 7)));
  // Level bar: 0..255 ramp so it reaches full at end of simulation
  // (the level bar primitive defaults to a 0..255 range, matching an
  // unsigned byte).
  addVar(
    _Var.bus('level_ramp', 8, (t) {
      final v = (t / _simulationDurationNs) * 255;
      return v.clamp(0, 255).floor();
    }),
  );
  // Analog sine and ramp.
  addVar(
    _Var.real('analog_sine', (t) {
      final phase = 2 * math.pi * (t / 4000); // 4 µs period
      return math.sin(phase);
    }),
  );
  addVar(
    _Var.real('analog_ramp', (t) {
      final cycle = (t % 5000) / 5000; // 5 µs sawtooth
      return cycle * 2 - 1; // -1..+1
    }),
  );
  upscope();

  // ── basys3 ───────────────────────────────────────────────────────────
  scope('basys3');
  // 16 LEDs driven by bits of a 16-bit counter that increments every
  // 200 ns — gives a recognizable binary running pattern.
  for (var i = 0; i < 16; i++) {
    addVar(_Var.scalar('led$i', _bitOfCounter(bit: i, stepNs: 200)));
  }
  // 16 switches: each one toggles at a unique rate so the user sees
  // motion across the whole row.
  for (var i = 0; i < 16; i++) {
    addVar(
      _Var.scalar('sw$i', _periodicScalar(periodNs: 400 + i * 60)),
    );
  }
  // 5 push buttons: short pulses at staggered times.
  for (final entry in const [
    ('btnC', 1500),
    ('btnU', 3000),
    ('btnL', 4500),
    ('btnR', 6000),
    ('btnD', 7500),
  ]) {
    final (name, pulseStartNs) = entry;
    addVar(_Var.scalar(name, _pulse(startNs: pulseStartNs, widthNs: 250)));
  }
  // Four 4-bit digits: each driven by a different nibble of a 16-bit
  // counter so the 4-digit display runs through interesting values.
  for (var i = 0; i < 4; i++) {
    addVar(
      _Var.bus('digit$i', 4, (t) {
        final v = (t ~/ 100) & 0xFFFF;
        return (v >> (i * 4)) & 0xF;
      }),
    );
  }
  upscope();

  // ── de10 ─────────────────────────────────────────────────────────────
  scope('de10');
  // 10 LEDs: bits of a 10-bit counter.
  for (var i = 0; i < 10; i++) {
    addVar(_Var.scalar('ledr$i', _bitOfCounter(bit: i, stepNs: 250)));
  }
  // 10 switches: alternating-state pattern with offsets.
  for (var i = 0; i < 10; i++) {
    addVar(
      _Var.scalar('sw$i', _periodicScalar(periodNs: 500 + i * 80)),
    );
  }
  // 2 keys.
  addVar(_Var.scalar('key0', _pulse(startNs: 2500, widthNs: 400)));
  addVar(_Var.scalar('key1', _pulse(startNs: 8500, widthNs: 400)));
  // 6 hex displays: each shows a different nibble of a wide counter.
  for (var i = 0; i < 6; i++) {
    addVar(
      _Var.bus('hex$i', 4, (t) {
        final v = (t ~/ 150) & 0xFFFFFF;
        return (v >> (i * 4)) & 0xF;
      }),
    );
  }
  upscope();

  upscope();
  return _Definitions(scopeLines, vars);
}

// ── value generators ──────────────────────────────────────────────────────

typedef _Generator = num Function(int t);

_Generator _periodicScalar({required int periodNs}) {
  return (t) => (t ~/ (periodNs ~/ 2)) % 2;
}

_Generator _counter({required int stepNs, required int modulo}) {
  return (t) => (t ~/ stepNs) % modulo;
}

_Generator _bitOfCounter({required int bit, required int stepNs}) {
  return (t) => ((t ~/ stepNs) >> bit) & 1;
}

_Generator _pulse({required int startNs, required int widthNs}) {
  return (t) => (t >= startNs && t < startNs + widthNs) ? 1 : 0;
}

/// 7-bit cathode pattern for hex digits 0..f. Bit ordering matches the
/// SegmentGlyph.fromCathodes contract used by the seven-segment widget:
/// bit 0 = a (top), bit 1 = b, …, bit 6 = g (middle). Active-high.
int _hexCathodePattern(int digit) {
  const table = [
    0x3F,
    0x06,
    0x5B,
    0x4F,
    0x66,
    0x6D,
    0x7D,
    0x07,
    0x7F,
    0x6F,
    0x77,
    0x7C,
    0x39,
    0x5E,
    0x79,
    0x71,
  ];
  return table[digit & 0xF];
}

// ── encoded var representation ────────────────────────────────────────────

class _Var {
  _Var._({
    required this.name,
    required this.bitWidth,
    required this.isReal,
    required _Generator generator,
  }) : _generator = generator;

  factory _Var.scalar(String name, _Generator g) =>
      _Var._(name: name, bitWidth: 1, isReal: false, generator: g);

  factory _Var.bus(String name, int bitWidth, _Generator g) =>
      _Var._(name: name, bitWidth: bitWidth, isReal: false, generator: g);

  factory _Var.real(String name, _Generator g) =>
      _Var._(name: name, bitWidth: 64, isReal: true, generator: g);

  final String name;
  final int bitWidth;
  final bool isReal;
  final _Generator _generator;
  late String idcode;

  num value(int t) => _generator(t);

  String encode(num value) {
    if (isReal) return 'r$value $idcode';
    if (bitWidth == 1) return '${(value as int) & 1}$idcode';
    final mask = (1 << bitWidth) - 1;
    final asInt = (value as int) & mask;
    return 'b${asInt.toRadixString(2).padLeft(bitWidth, '0')} $idcode';
  }
}

/// Hands out unique VCD identifier codes from the printable ASCII
/// range (33..126), expanding to multi-character codes after the first
/// 94 signals.
class _IdCodeGenerator {
  static const int _start = 33;
  static const int _end = 126;
  int _index = 0;

  String next() {
    const base = _end - _start + 1;
    var n = _index++;
    final chars = <int>[];
    do {
      chars.add(_start + n % base);
      n = n ~/ base;
    } while (n > 0);
    return String.fromCharCodes(chars);
  }
}
