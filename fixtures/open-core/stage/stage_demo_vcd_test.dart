// Sanity-checks the hand-crafted Stage demo VCD: confirms it parses
// cleanly and exposes the signal names that the Stage widgets and
// boards expect, so users can drop the file in the viewer and
// successfully bind every primitive.

import 'package:flutter_test/flutter_test.dart';
import 'package:wavecrux/domain/models/signal_filter.dart';
import 'package:wavecrux/services/waveform/wellen_provider.dart';

const String _path = 'test/fixtures/stage/stage_demo.vcd';

void main() {
  group('stage_demo.vcd', () {
    late WellenProvider provider;

    setUp(() async {
      provider = WellenProvider();
      await provider.openFile(_path);
    });

    tearDown(() => provider.close());

    test('exposes the primitive demo signals', () {
      const expectedPrimitives = [
        'top.primitives.led_blink',
        'top.primitives.led_slow',
        'top.primitives.toggle_a',
        'top.primitives.toggle_b',
        'top.primitives.seven_seg_value',
        'top.primitives.seven_seg_cathodes',
        'top.primitives.seven_seg_dp',
        'top.primitives.bus_byte',
        'top.primitives.bus_word',
        'top.primitives.fsm_state',
        'top.primitives.level_ramp',
        'top.primitives.analog_sine',
        'top.primitives.analog_ramp',
      ];

      final present = provider
          .findVariables(const SignalFilter())
          .map((v) => v.fullPath)
          .toSet();

      for (final path in expectedPrimitives) {
        expect(present, contains(path), reason: 'missing $path');
      }
    });

    test('exposes every Basys 3 board slot name', () {
      final present = provider
          .findVariables(const SignalFilter())
          .map((v) => v.fullPath)
          .toSet();

      // 16 LEDs.
      for (var i = 0; i < 16; i++) {
        expect(present, contains('top.basys3.led$i'));
      }
      // 16 switches.
      for (var i = 0; i < 16; i++) {
        expect(present, contains('top.basys3.sw$i'));
      }
      // 5 buttons.
      for (final name in ['btnC', 'btnU', 'btnL', 'btnR', 'btnD']) {
        expect(present, contains('top.basys3.$name'));
      }
      // 4 digits.
      for (var i = 0; i < 4; i++) {
        expect(present, contains('top.basys3.digit$i'));
      }
    });

    test('exposes every DE10-Lite board slot name', () {
      final present = provider
          .findVariables(const SignalFilter())
          .map((v) => v.fullPath)
          .toSet();

      for (var i = 0; i < 10; i++) {
        expect(present, contains('top.de10.ledr$i'));
        expect(present, contains('top.de10.sw$i'));
      }
      expect(present, contains('top.de10.key0'));
      expect(present, contains('top.de10.key1'));
      for (var i = 0; i < 6; i++) {
        expect(present, contains('top.de10.hex$i'));
      }
    });

    test('signals carry value transitions over the 0..20 µs range',
        () async {
      // The bus_byte counter should change many times across the run.
      final byte = provider
          .findVariables(const SignalFilter())
          .firstWhere((v) => v.fullPath == 'top.primitives.bus_byte');
      await provider.loadSignal(byte.signalRef);
      expect(provider.isSignalLoaded(byte.signalRef), isTrue);

      final transitions = provider.changesInRange(byte.signalRef, 0, 20000);
      expect(transitions.length, greaterThan(50));
    });
  });
}
