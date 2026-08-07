import 'package:flutter/material.dart';

class MarketplaceSearchBar extends StatelessWidget {
  const MarketplaceSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Hľadať plugin',
        hintText: 'Názov, autor alebo ID',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
