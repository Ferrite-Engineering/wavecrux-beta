// Integration test: the per-bit and vector Zybo Z7 VCD fixtures parse
// cleanly with the open-core `WellenProvider` and run the
// `BoardAutoBindService` against the Zybo Z7 slot map to produce the
// expected auto-binding behaviour.
//
// This is a thin smoke check on top of the unit tests in
// `test/features/stage_pro/widgets/boards/zybo_z7_stage_widget_test.dart`
// — the unit tests synthesize Variables in code; this test confirms
// the same scenarios hold against actual VCD files that ship in the
// `verification/` workflow.

import 'package:flutter_test/flutter_test.dart';
import 'package:wavecrux/domain/models/board_auto_bind_candidate.dart';
import 'package:wavecrux/domain/models/signal_filter.dart';
import 'package:wavecrux/domain/models/variable.dart';
import 'package:wavecrux/services/stage/board_auto_bind_service.dart';
import 'package:wavecrux/services/waveform/wellen_provider.dart';
import 'package:wavecrux_pro/features/stage_pro/widgets/boards/zybo_z7_stage_widget.dart';

const String _perBitPath =
    'test/fixtures/stage_pro/boards/zybo_z7/zybo_z7_per_bit.vcd';
const String _vectorPath =
    'test/fixtures/stage_pro/boards/zybo_z7/zybo_z7_vector.vcd';

Map<String, Variable> _byPath(WellenProvider provider) {
  final vars = provider.findVariables(const SignalFilter());
  return {for (final v in vars) v.fullPath: v};
}

/// Inverts the path-keyed signal map to a `signalRef → fullPath` map so
/// tests can assert the *logical* signal a binding points at without
/// caring whether the underlying provider stores raw VCD idcodes
/// (`WellenProvider`) or `signalRef.toString()` integers
/// (`WellenProvider`).
Map<String, String> _refToPath(Map<String, Variable> byPath) =>
    {for (final v in byPath.values) v.signalRef: v.fullPath};

void main() {
  const board = ZyboZ7StageWidget();
  const service = BoardAutoBindService();

  group('zybo_z7_per_bit.vcd', () {
    late WellenProvider provider;

    setUp(() async {
      provider = WellenProvider();
      await provider.openFile(_perBitPath);
    });

    tearDown(() => provider.close());

    test(
      'exposes 4 plain-LED bits, 2 RGB-LED bits, 4 switch bits, 4 button '
      'bits, HDMI in/out, and audio codec mic/headphone signals',
      () {
        final paths = _byPath(provider).keys.toSet();
        for (var i = 0; i < 4; i++) {
          expect(paths, contains('top.led_$i'));
        }
        for (final name in ZyboZ7StageWidget.rgbLedSlotNames) {
          expect(paths, contains('top.$name'));
        }
        for (var i = 0; i < 4; i++) {
          expect(paths, contains('top.sw_$i'));
        }
        for (var i = 0; i < 4; i++) {
          expect(paths, contains('top.btn$i'));
        }
        expect(paths, contains('top.hdmi_in_data'));
        expect(paths, contains('top.hdmi_out_data'));
        expect(paths, contains('top.mic_in'));
        expect(paths, contains('top.headphone_out'));
      },
    );

    test(
      'plain LED / switch / button slots resolve via the per-slot tier '
      "(buttons exact, leds and sws fuzzy because the fixture uses 'led_<i>')",
      () {
        final result = service.computeBindings(
          slots: board.slots,
          availableSignals: _byPath(provider),
        );
        // Buttons match exactly because the names are identical.
        for (var i = 0; i < 4; i++) {
          final btnC = result.candidates['btn$i'];
          expect(btnC, isNotNull);
          expect(
            btnC!.confidence,
            BoardAutoBindConfidence.exactMatch,
            reason: 'btn$i should match top.btn$i exactly',
          );
        }
        // led / sw slots fall through to fuzzy because the fixture uses
        // the underscore-suffixed form `led_<i>` rather than `led<i>`.
        for (var i = 0; i < 4; i++) {
          final ledC = result.candidates['led$i'];
          expect(ledC, isNotNull);
          expect(ledC!.confidence, isNot(BoardAutoBindConfidence.noMatch));
        }
        for (var i = 0; i < 4; i++) {
          final swC = result.candidates['sw$i'];
          expect(swC, isNotNull);
          expect(swC!.confidence, isNot(BoardAutoBindConfidence.noMatch));
        }
      },
    );

    test(
      'RGB-LED slots match exactly when the design exposes per-position '
      'top.led_rgb_5 / top.led_rgb_6 wires',
      () {
        final byPath = _byPath(provider);
        final refToPath = _refToPath(byPath);
        final result = service.computeBindings(
          slots: board.slots,
          availableSignals: byPath,
        );
        for (final name in ZyboZ7StageWidget.rgbLedSlotNames) {
          final c = result.candidates[name]!;
          expect(
            c.confidence,
            BoardAutoBindConfidence.exactMatch,
            reason: '$name should match top.$name verbatim',
          );
          expect(refToPath[c.binding?.signalRef], 'top.$name');
        }
      },
    );
  });

  group('zybo_z7_vector.vcd', () {
    late WellenProvider provider;

    setUp(() async {
      provider = WellenProvider();
      await provider.openFile(_vectorPath);
    });

    tearDown(() => provider.close());

    test(
      'exposes 4-bit leds, 2-bit led_rgb_, 4-bit sws, 4-bit button, 24-bit '
      'HDMI in/out, and 16-bit audio codec vectors',
      () {
        final variables = _byPath(provider);
        expect(variables['top.leds']?.bitWidth, 4);
        expect(variables['top.led_rgb_']?.bitWidth, 2);
        expect(variables['top.sws']?.bitWidth, 4);
        expect(variables['top.button']?.bitWidth, 4);
        expect(variables['top.hdmi_in_data']?.bitWidth, 24);
        expect(variables['top.hdmi_out_data']?.bitWidth, 24);
        expect(variables['top.mic_in']?.bitWidth, 16);
        expect(variables['top.headphone_out']?.bitWidth, 16);
      },
    );

    test('led0..led3 fan out across the 4-bit leds vector', () {
      final byPath = _byPath(provider);
      final refToPath = _refToPath(byPath);
      final result = service.computeBindings(
        slots: board.slots,
        availableSignals: byPath,
      );
      for (var i = 0; i < 4; i++) {
        final c = result.candidates['led$i']!;
        expect(c.confidence, BoardAutoBindConfidence.vectorFanOut);
        expect(refToPath[c.binding?.signalRef], 'top.leds');
        expect(c.binding?.bitIndex, i);
      }
    });

    test(
      'led_rgb_5 / led_rgb_6 fan out across the 2-bit led_rgb_ vector '
      '(family prefix matches the vector signal name)',
      () {
        final byPath = _byPath(provider);
        final refToPath = _refToPath(byPath);
        final result = service.computeBindings(
          slots: board.slots,
          availableSignals: byPath,
        );
        // The family resolver indexes RGB slots by their numeric suffix
        // (5, 6) but the vector fan-out emits bitIndex relative to the
        // family's minIndex — so led_rgb_5 → bit 0, led_rgb_6 → bit 1.
        final r5 = result.candidates['led_rgb_5']!;
        expect(r5.confidence, BoardAutoBindConfidence.vectorFanOut);
        expect(refToPath[r5.binding?.signalRef], 'top.led_rgb_');
        expect(r5.binding?.bitIndex, 0);
        final r6 = result.candidates['led_rgb_6']!;
        expect(r6.confidence, BoardAutoBindConfidence.vectorFanOut);
        expect(refToPath[r6.binding?.signalRef], 'top.led_rgb_');
        expect(r6.binding?.bitIndex, 1);
      },
    );

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

    test(
      'btn0..btn3 fan out across the 4-bit "button" vector via the '
      'auto-bind alias table (btn → button)',
      () {
        final byPath = _byPath(provider);
        final refToPath = _refToPath(byPath);
        final result = service.computeBindings(
          slots: board.slots,
          availableSignals: byPath,
        );
        for (var i = 0; i < 4; i++) {
          final c = result.candidates['btn$i']!;
          expect(c.confidence, BoardAutoBindConfidence.vectorFanOut);
          expect(refToPath[c.binding?.signalRef], 'top.button');
          expect(c.binding?.bitIndex, i);
        }
      },
    );
  });
}
