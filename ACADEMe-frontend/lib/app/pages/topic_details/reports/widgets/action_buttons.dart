import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onDownloadReport;
  final VoidCallback onShareScore;
  final bool isDownloading;
  final bool isSharing;

  const ActionButtons({
    super.key,
    required this.onDownloadReport,
    required this.onShareScore,
    this.isDownloading = false,
    this.isSharing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context,
            icon: Icons.picture_as_pdf,
            label: L10n.getTranslatedText(context, 'Download Report'),
            isLoading: isDownloading,
            onPressed: isDownloading || isSharing ? null : onDownloadReport,
            backgroundColor: isDarkMode ? Colors.blueGrey[800] : Colors.blue[50],
            iconColor: isDarkMode ? Colors.blue[200] : Colors.blue[800],
          ),
          _buildActionButton(
            context,
            icon: Icons.share,
            label: L10n.getTranslatedText(context, 'Share Score'),
            isLoading: isSharing,
            onPressed: isSharing || isDownloading ? null : onShareScore,
            backgroundColor: isDarkMode ? Colors.green[800] : Colors.green[50],
            iconColor: isDarkMode ? Colors.green[200] : Colors.green[800],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
    required Color? backgroundColor,
    required Color? iconColor,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(iconColor),
                ),
              )
            : Icon(icon, color: iconColor),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12, // Reduced font size to fit text in one line
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
          maxLines: 1, // Force single line
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // Reduced horizontal padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }
}