import 'package:flutter_test/flutter_test.dart';
import 'package:stavby_pro_release_manager/core/release_profiles/release_profile.dart';
import 'package:stavby_pro_release_manager/core/release_profiles/release_profile_validator.dart';

void main() {
  test('release profile JSON roundtrip preserves configuration', () {
    const source = ReleaseProfile(
      id: 'stavby_pro',
      name: 'STAVBY PRO',
      windowsProjectPath: r'C:\\projects\\windows',
      androidProjectPath: r'C:\\projects\\android',
      githubOwner: 'owner',
      githubRepository: 'repository',
      isDefault: true,
    );

    final restored = ReleaseProfile.fromJson(source.toJson());
    expect(restored.id, source.id);
    expect(restored.windowsProjectPath, source.windowsProjectPath);
    expect(restored.androidProjectPath, source.androidProjectPath);
    expect(restored.isDefault, isTrue);
  });

  test('validator requires at least one project path', () {
    const profile = ReleaseProfile(id: 'empty', name: 'Empty');
    final result = const ReleaseProfileValidator().validate(profile);
    expect(result.isValid, isFalse);
  });
}
