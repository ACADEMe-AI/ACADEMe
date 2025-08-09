import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: AcademeTheme.appColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            L10n.getTranslatedText(context, 'Privacy Policy'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '1. Introduction'),
              L10n.getTranslatedText(context,
                  'Welcome to ACADEMe, an AI-powered personalized education platform. This Privacy Policy explains how Team VISI0N ("we," "our," or "us") collects, uses, protects, and shares your personal information when you use our website, mobile application, and services (collectively, the "Platform").\n\nBy using ACADEMe, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree with this policy, please do not use our Platform.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '2. Company Information'),
              L10n.getTranslatedText(context,
                  'ACADEMe\nGuwahati, Assam - India\nacademe.noreply@gmail.com'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '3. Information We Collect'),
              '',
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '3.1 Personal Information'),
              L10n.getTranslatedText(context,
                  'We collect personal information that you voluntarily provide to us, including:\n\n• Name and contact information (email address, phone number)\n• Account credentials (username, password)\n• Educational information (academic level, subjects of interest, learning goals)\n• Profile information (age, location, educational background)\n• Communication data (messages, feedback, support requests)'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(
                  context, '3.2 Automatically Collected Information'),
              L10n.getTranslatedText(context,
                  '• Device information (IP address, browser type, device identifiers)\n• Usage data (pages visited, time spent, clicks, navigation patterns)\n• Performance data (app crashes, load times, errors)\n• Location data (general geographic location based on IP address)\n• Cookies and similar tracking technologies'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '3.3 AI-Generated Data'),
              L10n.getTranslatedText(context,
                  '• Learning analytics and progress tracking\n• Personalized recommendations and content suggestions\n• Performance predictions and assessments\n• Behavioral patterns and learning preferences\n• AI-generated insights about your educational journey'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '4. How We Use Your Information'),
              L10n.getTranslatedText(context,
                  'We use your information for the following purposes:'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '4.1 Educational Services'),
              L10n.getTranslatedText(context,
                  '• Provide personalized learning experiences and content\n• Create adaptive learning paths based on your progress\n• Generate AI-powered recommendations and insights\n• Track your educational progress and achievements\n• Facilitate multilingual learning support'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '4.2 Platform Operations'),
              L10n.getTranslatedText(context,
                  '• Create and manage your account\n• Authenticate users and prevent fraud\n• Provide customer support and respond to inquiries\n• Send important notifications and updates\n• Improve our Platform and develop new features'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '4.3 Legal Basis (GDPR)'),
              L10n.getTranslatedText(context,
                  '• Consent: AI processing, marketing communications\n• Contract: Providing educational services\n• Legitimate Interest: Platform improvement, security\n• Legal Obligation: Compliance with applicable laws'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(
                  context, '5. Information Sharing and Disclosure'),
              '',
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(
                  context, '5.1 Third-Party Service Providers'),
              L10n.getTranslatedText(context,
                  'We may share your information with trusted third parties who help us operate our Platform:\n\n• Firebase: Database and authentication services\n• Google Gemini: AI and machine learning services\n• ClickUp: Form processing and data collection\n• LibreTranslate & Whisper: Translation and speech processing\n• Railway & Docker: Cloud hosting and deployment'),
            ),
            _buildHighlightBox(
              context,
              L10n.getTranslatedText(
                  context, '5.2 We Do NOT Sell Personal Data'),
              L10n.getTranslatedText(context,
                  'We do not sell, rent, or trade your personal information to third parties for their marketing purposes.'),
            ),
            _buildSubSection(
              context,
              L10n.getTranslatedText(context, '5.3 Legal Requirements'),
              L10n.getTranslatedText(context,
                  'We may disclose your information if required by law, regulation, or legal process, or to protect our rights, property, or safety.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '6. Data Security'),
              L10n.getTranslatedText(context,
                  'We implement appropriate security measures to protect your information:\n\n• Encryption of data in transit and at rest\n• Secure authentication and access controls\n• Regular security assessments and updates\n• Limited access to personal data on a need-to-know basis\n• Incident response procedures for data breaches'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '7. Data Retention'),
              L10n.getTranslatedText(context,
                  'We retain your personal information for as long as necessary to:\n\n• Provide our educational services to you\n• Comply with legal obligations\n• Resolve disputes and enforce our agreements\n• Improve our Platform and services\n\nWhen you delete your account, we will delete or anonymize your personal information within 30 days, except where retention is required by law.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(
                  context, '8. International Data Transfers'),
              L10n.getTranslatedText(context,
                  'As a global education platform, your information may be transferred to and processed in countries other than your country of residence, including India and the United States. We ensure appropriate safeguards are in place to protect your information during international transfers.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '9. Your Privacy Rights'),
              L10n.getTranslatedText(context,
                  'Depending on your location, you may have the following rights:'),
            ),
            _buildRightsCard(context),
            _buildSection(
              context,
              L10n.getTranslatedText(
                  context, '10. AI and Automated Decision-Making'),
              L10n.getTranslatedText(context,
                  'Our Platform uses artificial intelligence to personalize your learning experience. This includes:\n\n• Automated content recommendations based on your learning history\n• AI-powered difficulty adjustments in assessments\n• Predictive analytics for learning outcomes\n• Natural language processing for multilingual support\n\nYou have the right to opt out of automated decision-making and request human review of AI-generated decisions that significantly affect you.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '11. Children\'s Privacy'),
              L10n.getTranslatedText(context,
                  'Our Platform is designed for users of all ages, including children under 13. We comply with applicable children\'s privacy laws, including COPPA. If you are under 13, please ensure your parent or guardian reviews this Privacy Policy and consents to your use of our Platform.\n\nParents and guardians can contact us to review, update, or delete their child\'s information.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(
                  context, '12. Cookies and Tracking Technologies'),
              L10n.getTranslatedText(context,
                  'We use cookies and similar technologies to:\n\n• Remember your preferences and settings\n• Analyze Platform usage and performance\n• Provide personalized content and features\n• Ensure security and prevent fraud\n\nYou can control cookies through your browser settings, but disabling cookies may affect Platform functionality.'),
            ),
            _buildSection(
              context,
              L10n.getTranslatedText(
                  context, '13. Updates to This Privacy Policy'),
              L10n.getTranslatedText(context,
                  'We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. We will notify you of significant changes by:\n\n• Posting the updated policy on our Platform\n• Sending email notifications for material changes\n• Updating the "Last Updated" date at the top of this policy'),
            ),
            _buildContactCard(context),
            _buildSection(
              context,
              L10n.getTranslatedText(context, '15. Governing Law'),
              L10n.getTranslatedText(context,
                  'This Privacy Policy is governed by the laws of India and applicable international data protection regulations, including but not limited to the Digital Personal Data Protection Act 2023, GDPR (for EU users), and CCPA (for California users).'),
            ),
            _buildFooter(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcademeTheme.appColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: AcademeTheme.appColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  L10n.getTranslatedText(context, 'Privacy Policy'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            L10n.getTranslatedText(context, 'Last Updated: January 1, 2025'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AcademeTheme.appColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightBox(
      BuildContext context, String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightsCard(BuildContext context) {
    final rights = [
      {
        'title': L10n.getTranslatedText(context, 'Access & Portability'),
        'description': L10n.getTranslatedText(context,
            'Request a copy of your personal data and transfer it to another service'),
        'icon': Icons.download,
      },
      {
        'title': L10n.getTranslatedText(context, 'Correction'),
        'description': L10n.getTranslatedText(
            context, 'Update or correct inaccurate personal information'),
        'icon': Icons.edit,
      },
      {
        'title': L10n.getTranslatedText(context, 'Deletion'),
        'description': L10n.getTranslatedText(
            context, 'Request deletion of your personal data'),
        'icon': Icons.delete,
      },
      {
        'title': L10n.getTranslatedText(context, 'Opt-Out'),
        'description': L10n.getTranslatedText(context,
            'Opt out of data processing for marketing or AI analytics'),
        'icon': Icons.block,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: rights.map((right) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AcademeTheme.appColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    right['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        right['title'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        right['description'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AcademeTheme.appColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AcademeTheme.appColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AcademeTheme.appColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.contact_support,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L10n.getTranslatedText(context, '14. Contact Us'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            L10n.getTranslatedText(context,
                'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:'),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildContactInfo(Icons.email, 'academe.noreply@gmail.com'),
          const SizedBox(height: 8),
          _buildContactInfo(Icons.location_on, 'Guwahati, Assam - India'),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AcademeTheme.appColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: AcademeTheme.appColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'ACADEMe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            L10n.getTranslatedText(
                context, '© 2025 ACADEMe. All rights reserved.'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            L10n.getTranslatedText(context, 'Developed by Team VISI0N'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
