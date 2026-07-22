import 'package:flutter_test/flutter_test.dart';
import 'package:wavecrux/features/stage/bundle/widget_bundle_reader.dart';
import 'package:wavecrux/features/stage/sdk/manifest/manifest_enums.dart';

/// Validates the committed community render-bridge fixture
/// (`community_gauge.wcrux-widget`, produced by
/// `tool/generate_community_widget_fixture.dart`). This is the real
/// manifest + `.riv` the integration_test / manual live-render pass loads;
/// the reader path is pure Dart so this guard runs headless.
void main() {
  const fixturePath =
      'test/fixtures/stage/community_widget/community_gauge.wcrux-widget';

  test('community fixture bundle loads and parses its manifest', () async {
    final bundle = await WidgetBundleReader().read(fixturePath);

    expect(bundle.manifest.id, 'com.wavecrux.test.community_gauge');
    expect(bundle.manifest.runtime, ManifestRuntime.rive);
    expect(bundle.manifest.runtimeAssetPath, 'runtime/community_gauge.riv');
    expect(
      bundle.manifest.signalBindings.map((b) => b.name),
      containsAll(<String>['rpm', 'redline', 'shift']),
    );
    // The rpm binding carries a linear normalizer parameter.
    expect(
      bundle.manifest.parameters.map((p) => p.binding),
      contains('rpm'),
    );

    // The reused Tachometer artboard bytes are present and non-empty.
    final riv = bundle.readAsset(bundle.manifest.runtimeAssetPath);
    expect(riv, isNotNull);
    expect(riv!.isNotEmpty, isTrue);
  });
}
