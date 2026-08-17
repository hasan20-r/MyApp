import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/group_invitation_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/hey_avatar.dart';

class GroupInvitationsModal extends StatefulWidget {
  final UserModel currentUser;
  final Function(String groupId)? onGroupJoined;

  const GroupInvitationsModal({
    super.key,
    required this.currentUser,
    this.onGroupJoined,
  });

  @override
  State<GroupInvitationsModal> createState() => _GroupInvitationsModalState();
}

class _GroupInvitationsModalState extends State<GroupInvitationsModal> {
  final FirestoreService _firestoreService = FirestoreService();
  final Set<String> _processingIds = {};

  void _accept(GroupInvitationModel invite) async {
    setState(() {
      _processingIds.add(invite.id);
    });

    try {
      await _firestoreService.acceptGroupInvitation(
        invitationId: invite.id,
        groupId: invite.groupId,
        user: widget.currentUser,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onGroupJoined?.call(invite.groupId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${invite.groupName}"! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: HeyTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(invite.id);
        });
      }
    }
  }

  void _decline(GroupInvitationModel invite) async {
    setState(() {
      _processingIds.add(invite.id);
    });

    try {
      await _firestoreService.declineGroupInvitation(invite.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined invitation to "${invite.groupName}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(invite.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(HeyTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, color: HeyTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Group Invitations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<GroupInvitationModel>>(
            stream: _firestoreService.streamUserGroupInvitations(widget.currentUser.uid),
            builder: (context, snapshot) {
              final invites = snapshot.data ?? [];

              if (invites.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 40,
                          color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No pending group invitations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'When community admins or friends invite you, they will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  final isBusy = _processingIds.contains(invite.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                      border: Border.all(
                        color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        HeyAvatar(
                          photoUrl: invite.groupPhotoUrl,
                          name: invite.groupName,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invite.groupName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Invited by ${invite.inviterName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: isBusy ? null : () => _decline(invite),
                              icon: const Icon(Icons.close_rounded, size: 20, color: HeyTheme.errorRed),
                              tooltip: 'Decline',
                            ),
                            ElevatedButton(
                              onPressed: isBusy ? null : () => _accept(invite),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HeyTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Join', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
