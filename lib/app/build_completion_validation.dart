String? validateBuildCompletionInputs({
  required bool workspaceReady,
  required bool identityReady,
  required bool createCommit,
  required bool createTag,
  required String commitMessage,
  required String tagName,
}) {
  final missing = <String>[
    if (!workspaceReady) 'vybraný workspace',
    if (!identityReady) 'načítaná identita',
    if (createCommit && commitMessage.trim().isEmpty) 'Commit Message',
    if (createTag && tagName.trim().isEmpty) 'názov tagu',
  ];
  if (missing.isEmpty) return null;
  return 'Chýba: ${missing.join(', ')}.';
}
