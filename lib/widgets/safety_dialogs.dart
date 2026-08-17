import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class HeySafetyDialogs {
  static final FirestoreService _firestoreService = FirestoreService();

  static const List<String> reportReasons = [
    'Spam, scams, or commercial abuse',
    'Harassment or bullying',
    'Hate speech or discrimination',
    'Inappropriate or explicit content',
    'Impersonation or fake identity',
    'Other community safety concern',
  ];

  static Future<void> showReportDialog(
    BuildContext context, {
    required UserModel targetUser,
    required String currentUserId,
    VoidCallback? onReported,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedReason = reportReasons.first;
    final TextEditingController detailsController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Report @${targetUser.username}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why are you reporting this user? Help us understand what went wrong.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                    borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                    border: Border.all(
                      color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedReason,
                      isExpanded: true,
                      dropdownColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: HeyTheme.primary),
                      items: reportReasons.map((reason) {
                        return DropdownMenuItem<String>(
                          value: reason,
                          child: Text(
                            reason,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => selectedReason = val);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Additional Details (Optional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: detailsController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe what happened...',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                      borderSide: BorderSide(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                      borderSide: BorderSide(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                      borderSide: const BorderSide(color: HeyTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        await _firestoreService.reportUser(
                          reportedByUid: currentUserId,
                          targetUid: targetUser.uid,
                          reason: selectedReason,
                          details: detailsController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onReported?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Report submitted for @${targetUser.username}. Thank you for keeping Hey Fans safe.'),
                              backgroundColor: HeyTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit report: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: HeyTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: HeyTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showBlockConfirmationDialog(
    BuildContext context, {
    required UserModel targetUser,
    required String currentUserId,
    VoidCallback? onBlocked,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: HeyTheme.errorRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block_rounded, color: HeyTheme.errorRed, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Block @${targetUser.username}?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(
            'They will no longer be able to message you, view your profile, or invite you to groups. Any mutual follow relationship will be removed.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        await _firestoreService.blockUser(
                          currentUserId: currentUserId,
                          blockedUserId: targetUser.uid,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onBlocked?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Blocked @${targetUser.username}.'),
                              backgroundColor: HeyTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to block: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: HeyTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: HeyTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Block User', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showUnblockConfirmationDialog(
    BuildContext context, {
    required UserModel targetUser,
    required String currentUserId,
    VoidCallback? onUnblocked,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
          ),
          title: Text(
            'Unblock @${targetUser.username}?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
            ),
          ),
          content: Text(
            'They will be able to view your profile and send you messages again.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setState(() => isSubmitting = true);
                      try {
                        await _firestoreService.unblockUser(
                          currentUserId: currentUserId,
                          blockedUserId: targetUser.uid,
                        );
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          onUnblocked?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unblocked @${targetUser.username}.'),
                              backgroundColor: HeyTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to unblock: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: HeyTheme.errorRed,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: HeyTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
