import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../widgets/language_selection_tile.dart';

class LanguageSelectionSheet extends StatefulWidget {
  final List<Map<String, String>> languages;
  final String selectedLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectionSheet({
    super.key,
    required this.languages,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionSheet> createState() => _LanguageSelectionSheetState();
}

class _LanguageSelectionSheetState extends State<LanguageSelectionSheet> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        List<Map<String, String>> filteredLanguages = widget.languages
            .where((language) => language['name']!
            .toLowerCase()
            .startsWith(searchQuery.toLowerCase()))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.getTranslatedText(context, 'Select Output Language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              TextField(
                decoration: InputDecoration(
                  labelText: L10n.getTranslatedText(context, 'Search Languages'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (query) {
                  setModalState(() {
                    searchQuery = query;
                  });
                },
              ),
              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: filteredLanguages.length,
                  itemBuilder: (context, index) {
                    var language = filteredLanguages[index];
                    return LanguageSelectionTile(
                      language: language['name']!,
                      code: language['code']!,
                      isSelected: widget.selectedLanguage == language['code'],
                      onTap: () {
                        widget.onLanguageSelected(language['code']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
