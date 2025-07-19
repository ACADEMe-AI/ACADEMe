import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/home/auth/auth_service.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/started/pages/login_view.dart';
import '../controllers/profile_controller.dart';
import '../models/user_model.dart';
import '../widgets/profile_class.dart';
import '../widgets/profile_dropdown.dart';
import '../widgets/language_selection_bottom_sheet.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final ProfileController _controller = ProfileController();
  late Locale _selectedLocale;
  String? selectedClass;
  UserModel? userDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _selectedLocale = const Locale('en');
    await _loadLanguage();
    await _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      final details = await _controller.loadUserDetails();
      setState(() {
        userDetails = UserModel(
          name: details['name'],
          email: details['email'],
          studentClass: details['student_class'],
          photoUrl: details['photo_url'],
        );
        selectedClass = details['student_class'] ?? 'SELECT';
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackbar(e.toString());
    }
  }

  Future<void> _loadLanguage() async {
    final locale = await _controller.loadLanguage();
    if (!mounted) return;

    final languageProvider =
    Provider.of<LanguageProvider>(context, listen: false);
    if (languageProvider.locale != locale) {
      languageProvider.setLocale(locale);
    }
    setState(() => _selectedLocale = locale);
  }

  void _showErrorSnackbar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${L10n.getTranslatedText(context, 'Failed to load user details:')} $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AcademeTheme.appColor,
          title: Text(
            L10n.getTranslatedText(context, 'Profile'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: SingleChildScrollView(
        child: _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        const SizedBox(height: 15),
        _buildUserAvatar(),
        const SizedBox(height: 10),
        _buildUserInfo(),
        const SizedBox(height: 20),
        _buildEditButton(),
        const SizedBox(height: 5),
        _buildOptionsList(),
      ],
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundImage:
      userDetails?.photoUrl != null && userDetails!.photoUrl!.isNotEmpty
          ? NetworkImage(userDetails!.photoUrl!)
          : const AssetImage('assets/design_course/userImage.png')
      as ImageProvider,
    );
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          userDetails?.name ?? 'Loading...',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          userDetails?.email ?? 'Loading...',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        L10n.getTranslatedText(context, 'Edit Profile'),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildOptionsList() {
    return ListView(
      padding: const EdgeInsets.all(10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildClassOption(),
        _buildLanguageOption(),
        _buildProfileOption(
          icon: Icons.settings,
          text: L10n.getTranslatedText(context, 'Settings'),
        ),
        _buildProfileOption(
          icon: Icons.credit_card,
          text: L10n.getTranslatedText(context, 'Billing Details'),
        ),
        _buildProfileOption(
          icon: Icons.info,
          text: L10n.getTranslatedText(context, 'Information'),
        ),
        _buildProfileOption(
          icon: Icons.card_giftcard,
          text: L10n.getTranslatedText(context, 'Redeem Me Points'),
        ),
        _buildLogoutOption(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildClassOption() {
    return GestureDetector(
      onTap: () => _showClassSelectionSheet(),
      child: ReusableProfileOption(
        icon: Icons.class_outlined,
        title: L10n.getTranslatedText(context, 'Class'),
        trailingWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedClass ?? 'SELECT',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption() {
    return GestureDetector(
      onTap: () => _showLanguageSelectionSheet(),
      child: ReusableProfileOption(
        icon: Icons.translate,
        title: L10n.getTranslatedText(context, 'language'),
        trailingWidget:
        Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String text,
  }) {
    return ProfileOption(
      icon: icon,
      text: text,
      iconColor: AcademeTheme.appColor,
      onTap: () {},
    );
  }

  Widget _buildLogoutOption() {
    return ProfileOption(
      icon: Icons.logout,
      text: L10n.getTranslatedText(context, 'Logout'),
      iconColor: Colors.red,
      onTap: _handleLogout,
      showTrailing: false,
    );
  }

  void _showClassSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(  // ✅ Correct - builder is separate
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClassSelectionBottomSheet(
          onClassSelected: () => _loadUserDetails(),
        ),
      ),
    );
  }

  void _showLanguageSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LanguageSelectionBottomSheet(
        selectedLocale: _selectedLocale,
        onLanguageSelected: (newLocale) =>
            _controller.changeLanguage(newLocale, context),
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService().signOut();
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LogInView()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(L10n.getTranslatedText(context, 'You have been logged out')),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
    }
  }
}
