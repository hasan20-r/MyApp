import 'package:flutter/material.dart';
import '../app/theme.dart';

class HeyAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final bool isOnline;
  final bool showPresence;

  const HeyAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
    this.isOnline = false,
    this.showPresence = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join('').toUpperCase()
        : 'F';

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: HeyTheme.primary.withOpacity(0.15),
          backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
              ? NetworkImage(photoUrl!)
              : null,
          child: photoUrl == null || photoUrl!.isEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.w700,
                    color: HeyTheme.primary,
                  ),
                )
              : null,
        ),
        if (showPresence && isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: HeyTheme.successGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
