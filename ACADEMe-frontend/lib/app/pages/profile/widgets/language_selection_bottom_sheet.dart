import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';

class LanguageSelectionBottomSheet extends StatefulWidget {
  final Locale selectedLocale;
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionBottomSheet({
    super.key,
    required this.selectedLocale,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionBottomSheet> createState() =>
      _LanguageSelectionBottomSheetState();
}

class _LanguageSelectionBottomSheetState
    extends State<LanguageSelectionBottomSheet> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.selectedLocale;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            L10n.getTranslatedText(context, 'Select Language'),
            style:
                TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildLanguageDropdown(width),
          const SizedBox(height: 20),
          _buildConfirmButton(width),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(double width) {
    return DropdownButtonFormField<Locale>(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      value: _selectedLocale,
      items: L10n.supportedLocales.map((locale) {
        return DropdownMenuItem(
          value: locale,
          child: Text(L10n.getLanguageName(locale.languageCode)),
        );
      }).toList(),
      onChanged: (locale) => setState(() => _selectedLocale = locale),
    );
  }

  Widget _buildConfirmButton(double width) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {
          if (_selectedLocale != null) {
            widget.onLanguageSelected(_selectedLocale!);
            Navigator.pop(context);
          }
        },
        child: Text(
          L10n.getTranslatedText(context, 'Confirm'),
          style: TextStyle(fontSize: width * 0.04, color: Colors.black),
        ),
      ),
    );
  }
}
