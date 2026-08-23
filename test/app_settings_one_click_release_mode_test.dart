import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/services/app_settings_service.dart';

void main() {
  test('One Click Release defaults to DEV', () {
    const settings = AppSettings();
    expect(settings.oneClickReleaseMode, 'DEV');
  });
}
