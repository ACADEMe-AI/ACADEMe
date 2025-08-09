import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';

/// **Modern text formatter class for recommendation display**
class RecommendationTextFormatter {
  /// **Main method to format recommendation text**
  static Widget formatText(String text, BuildContext context) {
    List<Widget> formattedWidgets = [];
    List<String> parts = text.split("\n");

    // Group related content into sections
    List<Widget> currentSection = [];
    String? currentSectionTitle;

    for (String part in parts) {
      // Skip lines that contain IDs
      if (_containsId(part)) {
        continue;
      }

      if (part.trim().isEmpty) {
        // End current section if we have content
        if (currentSection.isNotEmpty && currentSectionTitle != null) {
          formattedWidgets
              .add(_buildSection(currentSectionTitle, currentSection, context));
          currentSection = [];
          currentSectionTitle = null;
        }
        continue;
      }

      // Handle different types of content
      if (part.startsWith("# ")) {
        // Main heading - start new section
        if (currentSection.isNotEmpty && currentSectionTitle != null) {
          formattedWidgets
              .add(_buildSection(currentSectionTitle, currentSection, context));
          currentSection = [];
        }
        currentSectionTitle = part.replaceFirst("# ", "");
      } else if (part.startsWith("## ")) {
        // Sub heading
        currentSection.add(_buildSubHeading(part.replaceFirst("## ", "")));
      } else if (part.startsWith("### ")) {
        // Sub-sub heading
        currentSection.add(_buildSmallHeading(part.replaceFirst("### ", "")));
      } else if (part.startsWith("**") && part.endsWith("**")) {
        // Bold key-value pair
        currentSection.add(_buildKeyValuePair(part.replaceAll("**", ""), ""));
      } else if (part.startsWith("*") && part.endsWith("*")) {
        // Bold text
        currentSection.add(_buildKeyValuePair(part.replaceAll("*", ""), ""));
      } else if (part.startsWith("- ")) {
        // Bullet points
        currentSection
            .add(_buildModernBulletPoint(part.replaceFirst("- ", "")));
      } else if (part.startsWith(">")) {
        // Quote/highlight
        currentSection
            .add(_buildHighlightBox(part.replaceFirst(">", "").trim()));
      } else if (part.startsWith("`") && part.endsWith("`")) {
        // Code/technical term
        currentSection.add(_buildCodeBlock(part.replaceAll("`", "")));
      } else {
        // Regular text with inline formatting
        currentSection.add(_buildRegularText(part));
      }
    }

    // Add final section if exists
    if (currentSection.isNotEmpty && currentSectionTitle != null) {
      formattedWidgets
          .add(_buildSection(currentSectionTitle, currentSection, context));
    } else if (currentSection.isNotEmpty) {
      // If no title, add content directly
      formattedWidgets.addAll(currentSection);
    }

    // If no sections were created, show all content in one card
    if (formattedWidgets.isEmpty && parts.isNotEmpty) {
      formattedWidgets.add(_buildSection(
          "Your Analysis",
          [
            _buildRegularText(text),
          ],
          context));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedWidgets
          .map((widget) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: widget,
              ))
          .toList(),
    );
  }

  /// **Build a modern section card**
  static Widget _buildSection(
      String title, List<Widget> content, BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: AcademeTheme.appColor.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AcademeTheme.appColor.withOpacity(0.08),
                  AcademeTheme.appColor.withOpacity(0.03),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AcademeTheme.appColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSectionIcon(title),
                    color: AcademeTheme.appColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Section content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content
                  .map((widget) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: widget,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// **Get appropriate icon for section**
  static IconData _getSectionIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('progress') || lowerTitle.contains('analysis')) {
      return Icons.trending_up;
    } else if (lowerTitle.contains('recommendation') ||
        lowerTitle.contains('suggest')) {
      return Icons.lightbulb_outline;
    } else if (lowerTitle.contains('strength') || lowerTitle.contains('good')) {
      return Icons.stars;
    } else if (lowerTitle.contains('improvement') ||
        lowerTitle.contains('weak')) {
      return Icons.tablet;
    } else if (lowerTitle.contains('goal') ||
        lowerTitle.contains('objective')) {
      return Icons.flag_outlined;
    } else if (lowerTitle.contains('next') || lowerTitle.contains('action')) {
      return Icons.arrow_forward;
    }
    return Icons.analytics_outlined;
  }

  /// **Build sub heading**
  static Widget _buildSubHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  /// **Build small heading**
  static Widget _buildSmallHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AcademeTheme.appColor,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  /// **Build key-value pair with modern styling**
  static Widget _buildKeyValuePair(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AcademeTheme.appColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AcademeTheme.appColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.label_important,
            color: AcademeTheme.appColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Build modern bullet point**
  static Widget _buildModernBulletPoint(String text) {
    // Skip bullet points that contain IDs
    if (_containsId(text)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AcademeTheme.appColor,
                  AcademeTheme.appColor.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AcademeTheme.appColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _parseInlineBoldText(text),
          ),
        ],
      ),
    );
  }

  /// **Build highlight/quote box**
  static Widget _buildHighlightBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote,
            color: Colors.orange[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Build code block**
  static Widget _buildCodeBlock(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// **Build regular text with modern styling**
  static Widget _buildRegularText(String text) {
    return _parseInlineBoldText(text);
  }

  /// **Enhanced inline bold text parser with modern styling**
  static Widget _parseInlineBoldText(String text) {
    List<InlineSpan> spans = [];

    // Split by both ** and * for bold formatting
    List<String> parts = text.split(RegExp(r'(\*\*|\*)'));
    bool isBold = false;

    for (String part in parts) {
      if (part == '**' || part == '*') {
        isBold = !isBold;
        continue;
      }

      if (part.isEmpty) continue;

      spans.add(TextSpan(
        text: part,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: isBold ? AcademeTheme.appColor : Colors.grey[700],
          height: 1.5,
          letterSpacing: -0.2,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// **Helper function to detect if a line contains ID information**
  static bool _containsId(String text) {
    final idPatterns = [
      RegExp(r'\bID:\s*\d+', caseSensitive: false),
      RegExp(r'\bCourse\s*ID:\s*\d+', caseSensitive: false),
      RegExp(r'\bTopic\s*ID:\s*\d+', caseSensitive: false),
      RegExp(r'\bSubtopic\s*ID:\s*\d+', caseSensitive: false),
      RegExp(r'\bMaterial\s*ID:\s*\d+', caseSensitive: false),
      RegExp(r'\b\w+_id:\s*\d+', caseSensitive: false),
      RegExp(r'\bid\s*=\s*\d+', caseSensitive: false),
    ];

    return idPatterns.any((pattern) => pattern.hasMatch(text));
  }
}
