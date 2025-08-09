import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/localization/l10n.dart';
// Import your class selection bottom sheet
import '../../../../started/pages/class.dart'; // Update with your actual path

class ProfileClassPage extends StatefulWidget {
  const ProfileClassPage({super.key});

  @override
  State<ProfileClassPage> createState() => _ProfileClassPageState();
}

class _ProfileClassPageState extends State<ProfileClassPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _currentClass;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentClass();
  }

  Future<void> _loadCurrentClass() async {
    setState(() => _isLoading = true);

    try {
      final storedClass = await _secureStorage.read(key: 'student_class');
      if (mounted) {
        setState(() {
          _currentClass = storedClass;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentClass = null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showClassSelection() async {
    await showClassSelectionSheet(
      context,
      onClassSelected: () {
        debugPrint('Class selection completed');
      },
      onClassUpdated: (newClass) {
        // This is the key part - update the UI when class changes
        setState(() {
          _currentClass = newClass;
        });

        // Optional: Show a confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${L10n.getTranslatedText(context, 'Class updated to')} $newClass',
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.getTranslatedText(context, 'Profile - Class')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Class Display
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'Current Class'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                _currentClass ??
                                    L10n.getTranslatedText(
                                        context, 'No class selected'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                        IconButton(
                          onPressed: _loadCurrentClass,
                          icon: const Icon(Icons.refresh),
                          tooltip: L10n.getTranslatedText(context, 'Refresh'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Change Class Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showClassSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  L10n.getTranslatedText(context, 'Change Class'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Additional Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          L10n.getTranslatedText(context, 'Important Note'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L10n.getTranslatedText(context,
                          'Changing your class will reset all your progress data. Make sure you really want to switch before confirming.'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative approach using a StatefulWidget mixin for auto-refresh
mixin AutoRefreshClassMixin<T extends StatefulWidget> on State<T> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? currentClass;

  @override
  void initState() {
    super.initState();
    loadClassData();
  }

  Future<void> loadClassData() async {
    final storedClass = await _secureStorage.read(key: 'student_class');
    if (mounted) {
      setState(() {
        currentClass = storedClass;
      });
    }
  }

  // Call this method whenever you need to refresh class data
  Future<void> refreshClassData() async {
    await loadClassData();
  }
}

// Example of using the mixin in another widget
class AnotherProfileWidget extends StatefulWidget {
  const AnotherProfileWidget({super.key});

  @override
  State<AnotherProfileWidget> createState() => _AnotherProfileWidgetState();
}

class _AnotherProfileWidgetState extends State<AnotherProfileWidget>
    with AutoRefreshClassMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Current Class: ${currentClass ?? "Not set"}'),
            ElevatedButton(
              onPressed: () async {
                await showClassSelectionSheet(
                  context,
                  onClassSelected: () {},
                  onClassUpdated: (newClass) {
                    // Automatically refresh when class is updated
                    refreshClassData();
                  },
                );
              },
              child: const Text('Change Class'),
            ),
          ],
        ),
      ),
    );
  }
}
