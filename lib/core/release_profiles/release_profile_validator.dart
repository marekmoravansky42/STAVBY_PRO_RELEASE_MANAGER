import 'release_profile.dart';

class ReleaseProfileValidation {
  const ReleaseProfileValidation(this.errors);

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class ReleaseProfileValidator {
  const ReleaseProfileValidator();

  ReleaseProfileValidation validate(ReleaseProfile profile) {
    final errors = <String>[];
    if (profile.id.trim().isEmpty) errors.add('Profil nemá ID.');
    if (profile.name.trim().isEmpty) errors.add('Profil nemá názov.');
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(profile.id)) {
      errors.add('ID profilu môže obsahovať iba písmená, čísla, _ a -.');
    }
    if (profile.windowsProjectPath == null &&
        profile.androidProjectPath == null) {
      errors.add('Profil musí obsahovať aspoň jeden projekt.');
    }
    if ((profile.githubOwner == null) != (profile.githubRepository == null)) {
      errors.add('GitHub owner a repository musia byť vyplnené spolu.');
    }
    return ReleaseProfileValidation(List<String>.unmodifiable(errors));
  }

  void requireValid(ReleaseProfile profile) {
    final result = validate(profile);
    if (!result.isValid) {
      throw FormatException(result.errors.join(' '));
    }
  }
}
