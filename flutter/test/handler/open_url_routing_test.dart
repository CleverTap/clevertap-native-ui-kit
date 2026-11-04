import 'package:clevertap_native_display/clevertap_native_display.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// open_url handling: external-browser-only for now (custom tabs deferred). Every
// scheme goes to the OS via externalApplication — deeplinks / app URLs route to
// the registered app, http/https to the external browser. A host can intercept
// via onOpenUrl (mirrors native onOpenUrl -> Bool): returning true suppresses the
// SDK open entirely.
class _MockLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  String? lastUrl;
  PreferredLaunchMode? lastMode;
  int launchCount = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchCount++;
    lastUrl = url;
    lastMode = options.mode;
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLauncher mock;
  late UrlLauncherPlatform original;

  setUp(() {
    original = UrlLauncherPlatform.instance;
    mock = _MockLauncher();
    UrlLauncherPlatform.instance = mock;
  });
  tearDown(() => UrlLauncherPlatform.instance = original);

  NDAction openUrl(String url, {bool? openInBrowser, bool? customTabsEnabled}) =>
      NDAction.fromJson({
        'type': 'open_url',
        'url': url,
        if (openInBrowser != null) 'openInBrowser': openInBrowser,
        if (customTabsEnabled != null) 'customTabsEnabled': customTabsEnabled,
      });

  group('external-only routing (all schemes → externalApplication)', () {
    test('custom-scheme deeplink', () async {
      await const ActionHandler().handle(openUrl('myapp://product/42'), 'n');
      expect(mock.lastUrl, 'myapp://product/42');
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });

    test('tel:', () async {
      await const ActionHandler().handle(openUrl('tel:+15551234567'), 'n');
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });

    test('https', () async {
      await const ActionHandler().handle(openUrl('https://example.com'), 'n');
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });

    test('https with customTabsEnabled=true still external (custom tabs deferred)',
        () async {
      await const ActionHandler()
          .handle(openUrl('https://example.com', customTabsEnabled: true), 'n');
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });

    test('https with openInBrowser', () async {
      await const ActionHandler()
          .handle(openUrl('https://example.com', openInBrowser: true), 'n');
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });
  });

  group('host opt-out via onOpenUrl', () {
    test('returning true suppresses the SDK open', () async {
      String? interceptedUrl;
      bool? interceptedInBrowser;
      final handler = ActionHandler(onOpenUrl: (url, inBrowser) {
        interceptedUrl = url;
        interceptedInBrowser = inBrowser;
        return true; // host handled it
      });

      await handler.handle(openUrl('myapp://route', openInBrowser: true), 'n');

      expect(interceptedUrl, 'myapp://route');
      expect(interceptedInBrowser, true);
      expect(mock.launchCount, 0, reason: 'SDK must not open when host handled it');
    });

    test('returning false lets the SDK open it', () async {
      final handler = ActionHandler(onOpenUrl: (url, inBrowser) => false);
      await handler.handle(openUrl('https://example.com'), 'n');
      expect(mock.launchCount, 1);
      expect(mock.lastMode, PreferredLaunchMode.externalApplication);
    });
  });
}
