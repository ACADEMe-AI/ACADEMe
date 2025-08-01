import 'package:ACADEMe/api_endpoints.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ClassSelectionBottomSheet extends StatefulWidget {
  final VoidCallback onClassSelected;
  final Function(String)? onClassUpdated;

  const ClassSelectionBottomSheet({
    super.key,
    required this.onClassSelected,
    this.onClassUpdated,
  });

  @override
  State<ClassSelectionBottomSheet> createState() =>
      _ClassSelectionBottomSheetState();
}

class _ClassSelectionBottomSheetState extends State<ClassSelectionBottomSheet> {
  String? selectedClass;
  final List<String> classes = ['5'];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _storedClass;
  bool _isClassChanged = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStoredClass();
  }

  Future<void> _loadStoredClass() async {
    final storedClass = await _secureStorage.read(key: 'student_class');
    if (mounted) {
      setState(() {
        _storedClass = storedClass;
        selectedClass = storedClass;
        _isClassChanged = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            L10n.getTranslatedText(context, 'What class are you in?'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(L10n.getTranslatedText(context, 'Select class')),
            value: classes.contains(selectedClass) ? selectedClass : null,
            items: classes
                .map((className) => DropdownMenuItem(
              value: className,
              child: Text(className),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedClass = value;
                _isClassChanged = value != _storedClass;
              });
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isClassChanged && !_isLoading
                    ? _handleClassSelection
                    : null,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                  L10n.getTranslatedText(context, 'Confirm'),
                  style: const TextStyle(
                      fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleClassSelection() async {
    if (selectedClass == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'Please select a valid class'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _updateClassInBackend(selectedClass!);
      if (!success) return;

      // Update stored class reference
      _storedClass = selectedClass;
      _isClassChanged = false;

      // Notify parent widget FIRST
      if (widget.onClassUpdated != null) {
        widget.onClassUpdated!(selectedClass!);
      }

      // Then call the general callback
      widget.onClassSelected();

      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(L10n.getTranslatedText(context, 'An error occurred. Please try again.'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  Future<bool> _updateClassInBackend(String selectedClass) async {
    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'No access token found'));
      return false;
    }

    try {
      final response = await http.patch(
        ApiEndpoints.getUri(ApiEndpoints.updateClass),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'new_class': selectedClass}),
      );

      if (response.statusCode == 200) {
        // Store locally FIRST
        await _secureStorage.write(key: 'student_class', value: selectedClass);

        // Then re-login to get fresh data
        final reloginSuccess = await _reloginUser();
        if (reloginSuccess) {
          _showSnackBar('${L10n.getTranslatedText(context, 'Selected')} $selectedClass');
          return true;
        }
        return false;
      }

      if (response.statusCode == 401) {
        return await _reloginAndRetry(selectedClass);
      }

      _showSnackBar('${L10n.getTranslatedText(context, 'Failed to update class')}: ${response.body}');
      return false;
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'Network error. Please try again.'));
      return false;
    }
  }

  Future<bool> _reloginAndRetry(String selectedClass) async {
    final bool reloginSuccess = await _reloginUser();
    if (reloginSuccess) {
      return await _updateClassInBackend(selectedClass);
    }
    return false;
  }

  Future<bool> _reloginUser() async {
    final String? email = await _secureStorage.read(key: 'email');
    final String? password = await _secureStorage.read(key: 'password');

    if (email == null || password == null) {
      _showSnackBar(L10n.getTranslatedText(context, 'Session expired. Please login again.'));
      return false;
    }

    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await _secureStorage.write(
            key: 'access_token', value: responseData['access_token']);
        return true;
      }

      _showSnackBar(L10n.getTranslatedText(context, 'Login failed. Please login manually.'));
      return false;
    } catch (e) {
      _showSnackBar(L10n.getTranslatedText(context, 'Network error during login'));
      return false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Updated function to show class selection sheet
Future<void> showClassSelectionSheet(
    BuildContext context, {
      VoidCallback? onClassSelected,
      Function(String)? onClassUpdated,
    }) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => ClassSelectionBottomSheet(
      onClassSelected: onClassSelected ?? () {
        debugPrint('Class selected successfully');
      },
      onClassUpdated: onClassUpdated,
    ),
  );
}