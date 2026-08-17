import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../providers/auth_provider.dart';
import '../screens/notifications/notifications_screen.dart';
import '../services/firestore_service.dart';

class HeyNotificationButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onCustomTap;

  const HeyNotificationButton({
    super.key,
    this.color,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return IconButton(
        icon: Icon(Icons.notifications_none_rounded, color: color),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
      );
    }

    final firestoreService = FirestoreService();

    return StreamBuilder<int>(
      stream: firestoreService.streamUnreadNotificationsCount(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                color: unreadCount > 0 ? HeyTheme.primary : color,
              ),
              onPressed: () {
                if (onCustomTap != null) {
                  onCustomTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                }
              },
            ),
            if (unreadCount > 0)
              Positioned(
                top: 8,
                right: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: HeyTheme.errorRed,
                      borderRadius: BorderRadius.circular(HeyTheme.radiusPill),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? HeyTheme.darkSurface
                            : HeyTheme.lightSurface,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
