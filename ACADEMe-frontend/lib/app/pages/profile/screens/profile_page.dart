import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/app/auth/auth_service.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:ACADEMe/started/pages/login_view.dart';
import '../../../../started/pages/class.dart';
import '../../../common/widgets/coming_soon_popup.dart';
import '../controllers/profile_controller.dart';
import '../models/user_model.dart';
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

  UserModel? _currentUserDetails;
  Locale? _currentLocale;
  String? _currentClass;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _selectedLocale = const Locale('en');

    // Always load fresh data, no cache checking
    await _loadLanguage();
    await _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    try {
      setState(() => isLoading = true);

      final details = await _controller.loadUserDetails();
      final newUserDetails = UserModel(
        name: details['name'],
        email: details['email'],
        studentClass: details['student_class'],
        photoUrl: details['photo_url'],
      );

      setState(() {
        userDetails = newUserDetails;
        selectedClass = details['student_class']?.isNotEmpty == true
            ? details['student_class']
            : null;
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

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (languageProvider.locale != locale) {
      languageProvider.setLocale(locale);
    }

    setState(() => _selectedLocale = locale);
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _loadLanguage();
    await _loadUserDetails();
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
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
          actions: [
            // Add refresh button for manual refresh
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _refreshData,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const ProfilePageShimmer()
          : RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: _buildProfileContent(),
        ),
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
          userDetails?.name ?? 'User',
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
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => ComingSoonPopup(
            featureName: L10n.getTranslatedText(context, 'Edit Profile'),
            icon: Icons.edit,
            description: L10n.getTranslatedText(context, 'Customize your profile information and preferences.'),
          ),
        );
      },
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
        // _buildProfileOption(
        //   icon: Icons.credit_card,
        //   text: L10n.getTranslatedText(context, 'Billing Details'),
        // ),
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
            Text(
              selectedClass ?? L10n.getTranslatedText(context, 'SELECT'), // Fix
              style: const TextStyle(fontSize: 16),
            ),
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
      onTap: () {
        String description = '';
        if (text.contains('Settings')) {
          description = L10n.getTranslatedText(context, 'Manage your app preferences and account settings.');
        } else if (text.contains('Information')) {
          description = L10n.getTranslatedText(context, 'Learn more about ACADEMe and our features.');
        } else if (text.contains('Redeem')) {
          description = L10n.getTranslatedText(context, 'Use your earned points to unlock exclusive rewards.');
        }

        showDialog(
          context: context,
          builder: (context) => ComingSoonPopup(
            featureName: text,
            icon: icon,
            description: description,
          ),
        );
      },
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ClassSelectionBottomSheet(
          onClassSelected: () async {
            // Set loading state
            setState(() {
              isLoading = true;
            });

            // Add a small delay to ensure the backend update is complete
            await Future.delayed(const Duration(milliseconds: 500));

            // Reload user details from backend
            await _loadUserDetails();
          },
          // Add this callback for immediate UI update
          onClassUpdated: (newClass) {
            setState(() {
              selectedClass = newClass;
              if (userDetails != null) {
                userDetails = UserModel(
                  name: userDetails!.name,
                  email: userDetails!.email,
                  studentClass: newClass,
                  photoUrl: userDetails!.photoUrl,
                );
              }
            });
          },
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
        onLanguageSelected: (newLocale) async {
          await _controller.changeLanguage(newLocale, context);
          setState(() => _selectedLocale = newLocale);
        },
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

// ... rest of the file (shimmer components) remains unchanged ...

// Base Shimmer Effect Widget
class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

// Reusable Shimmer Components
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ShimmerEffect(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double radius;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({
    super.key,
    required this.radius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ShimmerEffect(
        child: CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
        ),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsetsGeometry? margin;

  const ShimmerLine({
    super.key,
    this.width,
    this.height = 16.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: 4.0,
      margin: margin,
    );
  }
}

class ShimmerButton extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerButton({
    super.key,
    this.width,
    this.height = 45.0,
    this.borderRadius = 30.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerCard({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry? margin;
  final bool showLeading;
  final bool showTrailing;

  const ShimmerListTile({
    super.key,
    this.height = 60.0,
    this.margin,
    this.showLeading = true,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: ShimmerEffect(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (showLeading) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade400,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              if (showTrailing) ...[
                const SizedBox(width: 16),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Pre-built Shimmer Layouts
class ProfilePageShimmer extends StatelessWidget {
  const ProfilePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 15),
          // Avatar shimmer
          const ShimmerCircle(radius: 50),
          const SizedBox(height: 10),
          // Name shimmer
          const ShimmerLine(width: 150, height: 24),
          const SizedBox(height: 8),
          // Email shimmer
          const ShimmerLine(width: 200, height: 18),
          const SizedBox(height: 20),
          // Edit button shimmer
          const ShimmerButton(width: 120),
          const SizedBox(height: 20),
          // Options list shimmer
          ListView.builder(
            padding: const EdgeInsets.all(10),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              return const ShimmerListTile();
            },
          ),
        ],
      ),
    );
  }
}

class FullPageShimmer extends StatelessWidget {
  const FullPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Search field shimmer
        const ShimmerBox(height: 48, borderRadius: 26),
        const SizedBox(height: 20),

        // Ask Me Card shimmer
        const ShimmerCard(height: 120),
        const SizedBox(height: 20),

        // Progress Card shimmer
        const ShimmerCard(height: 100),
        const SizedBox(height: 20),

        // Continue Learning section shimmer
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLine(width: 150, height: 20),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return ShimmerCard(
                    width: 160,
                    height: 180,
                    margin: const EdgeInsets.only(right: 12),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Banner shimmer
        const ShimmerCard(height: 120),
        const SizedBox(height: 16),

        // All Courses header shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const ShimmerLine(width: 100, height: 18),
            const ShimmerLine(width: 60, height: 16),
          ],
        ),
        const SizedBox(height: 16),

        // Course tags shimmer
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(6, (index) {
            return ShimmerBox(
              height: 32,
              width: 80 + (index * 10).toDouble(),
              borderRadius: 16,
            );
          }),
        ),
        const SizedBox(height: 16),

        // My Courses header shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const ShimmerLine(width: 100, height: 18),
            const ShimmerLine(width: 60, height: 16),
          ],
        ),
        const SizedBox(height: 16),

        // Courses grid shimmer
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return const ShimmerCard(height: double.infinity);
          },
        ),
        const SizedBox(height: 16),

        // Recommended section shimmer
        const ShimmerLine(width: 120, height: 18),
        const SizedBox(height: 12),

        // Recommended courses shimmer
        SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: const ShimmerCard(height: 160),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: const ShimmerCard(height: 160),
              ),
            ],
          ),
        ),
      ],
    );
  }
}