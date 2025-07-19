import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../localization/l10n.dart';

class SearchUI extends StatelessWidget {
  final ValueNotifier<bool> showSearchUI;

  const SearchUI({super.key, required this.showSearchUI});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showSearchUI.value = false;
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
        return false;
      },
      child: GestureDetector(
        onTap: () {
          showSearchUI.value = false;
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ));
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "${L10n.getTranslatedText(context, 'Search')}...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'Popular Searches'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Machine Learning')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Data Science')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(
                                  L10n.getTranslatedText(context, 'Flutter')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Linear Algebra')),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          L10n.getTranslatedText(context, 'Search Results'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: List.generate(3, (index) => ListTile(
                            leading: const Icon(Icons.book),
                            title: Text("Course ${index + 1}"),
                            onTap: () {},
                          )),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          L10n.getTranslatedText(context, 'Recent Searches'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(L10n.getTranslatedText(
                              context, 'Advanced Python')),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(L10n.getTranslatedText(
                              context, 'Cyber Security')),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}