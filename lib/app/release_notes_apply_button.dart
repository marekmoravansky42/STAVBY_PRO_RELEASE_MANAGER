import 'package:flutter/material.dart';

class ReleaseNotesApplyButton extends StatefulWidget {
  const ReleaseNotesApplyButton({
    super.key,
    required this.news,
    required this.fixes,
    required this.onApply,
  });

  final TextEditingController news;
  final TextEditingController fixes;
  final VoidCallback onApply;

  @override
  State<ReleaseNotesApplyButton> createState() =>
      _ReleaseNotesApplyButtonState();
}

class _ReleaseNotesApplyButtonState extends State<ReleaseNotesApplyButton> {
  bool _emptyProposal = false;

  void _apply() {
    if (widget.news.text.trim().isEmpty && widget.fixes.text.trim().isEmpty) {
      setState(() => _emptyProposal = true);
      return;
    }
    widget.onApply();
    setState(() => _emptyProposal = false);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FilledButton.tonalIcon(
            onPressed: _apply,
            icon: const Icon(Icons.publish_rounded),
            label: const Text('POUŽIŤ PRE RELEASE NOTES'),
          ),
          if (_emptyProposal)
            Text(
              'Návrh je prázdny. Najprv načítajte históriu alebo zadajte novinky či opravy.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
}
