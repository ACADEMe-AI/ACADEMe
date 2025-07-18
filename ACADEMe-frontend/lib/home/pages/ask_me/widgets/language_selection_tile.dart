import 'package:flutter/material.dart';

class LanguageSelectionTile extends StatelessWidget {
  final String language;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageSelectionTile({
    super.key,
    required this.language,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
      onTap: onTap,
    );
  }
}
