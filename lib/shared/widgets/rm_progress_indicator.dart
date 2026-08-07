import 'package:flutter/material.dart';

class RMProgressIndicator extends StatelessWidget {
  const RMProgressIndicator({super.key, this.value, this.label});
  final double? value;
  final String? label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (label != null) ...<Widget>[
            Text(label!, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
          ],
          LinearProgressIndicator(value: value),
        ],
      );
}
