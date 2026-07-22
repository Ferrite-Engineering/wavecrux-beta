// Integration test: the per-bit and vector DE10-Nano VCD fixtures
// parse cleanly with the open-core `WellenProvider` and run the
// `BoardAutoBindService` against the DE10-Nano slot map to produce
// the expected auto-binding behaviour.
//
// This is a thin smoke check on top of the unit tests in
// `test/features/stage_pro/widgets/boards/de10_nano_stage_widget_test.dart`
// — the unit tests synthesize Variables in code; this test confirms
// the same scenarios hold against actual VCD files that ship in the
// `verification/` workflow.

import 'package:flutter_test/flutter_test.dart';
import 'package:wavecrux/domain/models/board_auto_bind_candidate.dart';
import 'package:wavecrux/domain/models/signal_filter.dart';
import 'package:wavecrux/domain/models/variable.dart';
import 'package:wavecrux/services/stage/board_auto_bind_service.dart';
import 'package:wavecrux/services/waveform/wellen_provider.dart';
import 'package:wavecrux_pro/features/stage_pro/widgets/boards/de10_nano_stage_widget.dart';

const String _perBitPath =
    'test/fixtures/stage_pro/boards/de10_nano/de10_nano_per_bit.vcd';
const String _vectorPath =
    'test/fixtures/stage_pro/boards/de10_nano/de10_nano_vector.vcd';

Map<String, Variable> _byPath(WellenProvider provider) {
  final vars = provider.findVariables(const SignalFilter());
  return {for (final v in vars) v.fullPath: v};
}

/// Inverts the path-keyed signal map to a `signalRef → fullPath` map so
/// tests can assert the *logical* signal a binding points at without
/// caring whether the underlying provider stores raw VCD idcodes
/// (`WellenProvider`) or `signalRef.toString()` integers
/// (`WellenProvider`).
Map<String, String> _refToPath(Map<String, Variable> byPath) => {
  for (final v in byPath.values) v.signalRef: v.fullPath,
};

void main() {
  const board = De10NanoStageWidget();
  const service = BoardAutoBindService();

  group('de10_nano_per_bit.vcd', () {
    late WellenProvider provider;

    setUp(() async {
      provider = WellenProvider();
      await provider.openFile(_perBitPath);
    });

    tearDown(() => provider.close());

    test(
      'exposes 8 LED bits, 4 switch bits, 2 buttons, peripherals, and 8 ADC '
      'channels',
      () {
        final paths = _byPath(provider).keys.toSet();
        for (var i = 0; i < 8; i++) {
          expect(paths, contains('top.led_$i'));
        }
        for (var i = 0; i < 4; i++) {
          expect(paths, contains('top.sw_$i'));
        }
        for (final name in De10NanoStageWidget.buttonNames) {
          expect(paths, contains('top.$name'));
        }
        expect(paths, contains('top.hdmi_out_data'));
        expect(paths, contains('top.accel_xyz'));
        for (var i = 0; i < 8; i++) {
          expect(paths, contains('top.adc_ch_$i'));
        }
      },
    );

    test('LED / switch / button / ADC slots resolve via the per-slot tier', () {
      final result = service.computeBindings(
        slots: board.slots,
        availableSignals: _byPath(provider),
      );
      // Buttons are exact since the names match verbatim.
      for (final name in De10NanoStageWidget.buttonNames) {
        expect(
          result.candidates[name]?.confidence,
          BoardAutoBindConfidence.exactMatch,
          reason: 'button $name should match exactly',
        );
      }
      // led / sw / adc_ch slots fall through to fuzzy because the
      // fixture uses the underscore-suffixed form `led_<i>` rather
      // than `led<i>`.
      for (var i = 0; i < 8; i++) {
        final ledC = result.candidates['led$i'];
        expect(ledC, isNotNull);
        expect(ledC!.confidence, isNot(BoardAutoBindConfidence.noMatch));
      }
      for (var i = 0; i < 4; i++) {
        final swC = result.candidates['sw$i'];
        expect(swC, isNotNull);
        expect(swC!.confidence, isNot(BoardAutoBindConfidence.noMatch));
      }
      for (var i = 0; i < 8; i++) {
        final adcC = result.candidates['adc_ch$i'];
        expect(adcC, isNotNull);
        expect(adcC!.confidence, isNot(BoardAutoBindConfidence.noMatch));
      }
    });
  });

  group('de10_nano_vector.vcd', () {
    late WellenProvider provider;

    setUp(() async {
      provider = WellenProvider();
      await provider.openFile(_vectorPath);
    });

    tearDown(() => provider.close());

    test('exposes 8-bit leds, 4-bit sws, 24-bit hdmi, 36-bit accel, '
        '96-bit adc_ch vectors with individual buttons', () {
      final variables = _byPath(provider);
      expect(variables['top.leds']?.bitWidth, 8);
      expect(variables['top.sws']?.bitWidth, 4);
      expect(variables['top.hdmi_out_data']?.bitWidth, 24);
      expect(variables['top.accel_xyz']?.bitWidth, 36);
      expect(variables['top.adc_ch']?.bitWidth, 96);
      for (final name in De10NanoStageWidget.buttonNames) {
        expect(variables, contains('top.$name'));
      }
    });

    test('led0..led7 fan out across the 8-bit leds vector', () {
      final byPath = _byPath(provider);
      final refToPath = _refToPath(byPath);
      final result = service.computeBindings(
        slots: board.slots,
        availableSignals: byPath,
      );
      for (var i = 0; i < 8; i++) {
        final c = result.candidates['led$i']!;
        expect(c.confidence, BoardAutoBindConfidence.vectorFanOut);
        expect(refToPath[c.binding?.signalRef], 'top.leds');
        expect(c.binding?.bitIndex, i);
      }
    });

    test('sw0..sw3 fan out across the 4-bit sws vector', () {
      final byPath = _byPath(provider);
      final refToPath = _refToPath(byPath);
      final result = service.computeBindings(
        slots: board.slots,
        availableSignals: byPath,
      );
      for (var i = 0; i < 4; i++) {
        final c = result.candidates['sw$i']!;
        expect(c.confidence, BoardAutoBindConfidence.vectorFanOut);
        expect(refToPath[c.binding?.signalRef], 'top.sws');
        expect(c.binding?.bitIndex, i);
      }
    });

    test('buttons match the corresponding singleton signals exactly', () {
      final byPath = _byPath(provider);
      final refToPath = _refToPath(byPath);
      final result = service.computeBindings(
        slots: board.slots,
        availableSignals: byPath,
      );
      for (final name in De10NanoStageWidget.buttonNames) {
        final c = result.candidates[name]!;
        expect(c.confidence, BoardAutoBindConfidence.exactMatch);
        expect(refToPath[c.binding?.signalRef], 'top.$name');
      }
    });
  });
}
