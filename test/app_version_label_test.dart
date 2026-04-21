import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_app/config/app_version.dart';

void main() {
  test('fallback version constants match pubspec style', () {
    expect(kAppVersionFallback, isNotEmpty);
    expect(kAppBuildFallback, isNotEmpty);
    expect(kAppVersionFallback.contains('.'), isTrue);
  });
}
