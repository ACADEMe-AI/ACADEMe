import 'package:ACADEMe/api_endpoints.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/auth/auth_service.dart';
import '../../app/pages/courses/controllers/course_controller.dart';
import '../../app/pages/homepage/controllers/home_controller.dart';

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
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
      _showSnackBar(
          L10n.getTranslatedText(context, 'Please select a valid class'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _updateClassInBackend(selectedClass!);
      if (!success) {
        setState(() => _isLoading = false);
        return;
      }

      // Update stored class reference
      _storedClass = selectedClass;
      _isClassChanged = false;

      // CRITICAL: Force fetch fresh user data from backend
      final authService = AuthService();
      final freshUserDetails = await authService.getUserDetails();

      if (freshUserDetails != null) {
        // Update secure storage with fresh data
        await _secureStorage.write(key: 'name', value: freshUserDetails['name']);
        await _secureStorage.write(key: 'email', value: freshUserDetails['email']);
        await _secureStorage.write(key: 'student_class', value: freshUserDetails['student_class']);
        await _secureStorage.write(key: 'photo_url', value: freshUserDetails['photo_url']);

        debugPrint("Fresh user data updated in storage: class=${freshUserDetails['student_class']}");
      }

      // Clear all course caches AFTER updating user data
      try {
        final homeController = HomeController();
        homeController.clearCache();
        homeController.clearUserCache(); // This will force refetch on next access

        final courseController = CourseController();
        courseController.clearAllCaches();

        debugPrint("All caches cleared after class change");
      } catch (e) {
        debugPrint("Error clearing caches: $e");
      }

      // Notify parent widget
      if (widget.onClassUpdated != null) {
        widget.onClassUpdated!(selectedClass!);
      }

      // Call the general callback
      widget.onClassSelected();

      // Close the bottom sheet
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error in class selection: $e');
      if (mounted) {
        _showSnackBar(L10n.getTranslatedText(
            context, 'An error occurred. Please try again.'));
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
      debugPrint("🔄 Sending class update to backend: $selectedClass");

      final response = await http.patch(
        ApiEndpoints.getUri(ApiEndpoints.updateClass),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'new_class': selectedClass}),
      );

      debugPrint("📡 Backend response status: ${response.statusCode}");
      debugPrint("📡 Backend response body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse response to get updated user data
        final responseData = jsonDecode(response.body);
        debugPrint("✅ Backend confirmed class update: ${responseData}");

        // Store the updated class locally
        await _secureStorage.write(key: 'student_class', value: selectedClass);

        // After backend confirms, update BOTH storages
        final userData = responseData['user_data'];
        if (userData != null) {
          // Update FlutterSecureStorage
          await _secureStorage.write(key: 'student_class', value: userData['student_class']);
          await _secureStorage.write(key: 'name', value: userData['name']);
          await _secureStorage.write(key: 'email', value: userData['email']);
          await _secureStorage.write(key: 'photo_url', value: userData['photo_url']);

          // CRITICAL: Also update SharedPreferences immediately
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('student_class', userData['student_class']);

          debugPrint("✅ Updated BOTH storages with backend user_data: class=${userData['student_class']}");
        }

        _showSnackBar('${L10n.getTranslatedText(context, 'Selected')} $selectedClass');
        return true;
      }

      if (response.statusCode == 401) {
        _showSnackBar(L10n.getTranslatedText(context, 'Session expired. Please login again.'));
        return false;
      }

      debugPrint("❌ Backend update failed: ${response.body}");
      _showSnackBar('${L10n.getTranslatedText(context, 'Failed to update class')}: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating class: $e');
      _showSnackBar(L10n.getTranslatedText(context, 'Network error. Please try again.'));
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
      onClassSelected: onClassSelected ??
          () {
            debugPrint('Class selected successfully');
          },
      onClassUpdated: onClassUpdated,
    ),
  );
}
