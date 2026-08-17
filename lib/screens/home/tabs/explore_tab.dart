import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/hey_avatar.dart';
import '../../../widgets/hey_notification_button.dart';
import '../../profile/user_profile_modal.dart';

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _results = [];
  bool _isSearching = false;

  // Sample explore users for instant discovery
  final List<UserModel> _suggestedUsers = [
    UserModel(
      uid: 'user_fan_1',
      email: 'maya@heyfans.app',
      displayName: 'Maya Lin',
      username: 'mayafans',
      bio: 'Anime & Gaming fandom enthusiast 🎮✨',
      followersCount: 342,
      followingCount: 120,
      friendsCount: 45,
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime(2026, 1, 15),
      updatedAt: DateTime.now(),
    ),
    UserModel(
      uid: 'user_fan_2',
      email: 'david@heyfans.app',
      displayName: 'David K.',
      username: 'david_music',
      bio: 'Concert goer & Vinyl collector 🎵',
      followersCount: 890,
      followingCount: 310,
      friendsCount: 112,
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 25)),
      createdAt: DateTime(2025, 11, 8),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final list = await _firestoreService.searchUsers(query);
      if (mounted) {
        setState(() {
          _results = list;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _openUserProfile(UserModel user) async {
    final currentUid = Provider.of<AuthProvider>(context, listen: false).currentUser?.uid;
    bool initialFollowing = false;
    if (currentUid != null && currentUid != user.uid) {
      try {
        initialFollowing = await _firestoreService.isFollowing(
          currentUserId: currentUid,
          targetUserId: user.uid,
        );
      } catch (_) {
        initialFollowing = false;
      }
    }

    if (!mounted) return;

    UserProfileModal.show(
      context,
      user: user,
      isFollowing: initialFollowing,
      onToggleFollow: () {
        if (currentUid != null && currentUid != user.uid) {
          _firestoreService.toggleFollow(
            currentUserId: currentUid,
            targetUserId: user.uid,
            isCurrentlyFollowing: initialFollowing,
          );
        }
      },
      onSendMessage: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting chat with @${user.username}...'),
            backgroundColor: HeyTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = _searchController.text.trim().isNotEmpty ? _results : _suggestedUsers;

    return Scaffold(
      backgroundColor: isDark ? HeyTheme.darkBackground : HeyTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Explore Fans'),
        actions: const [
          HeyNotificationButton(),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _handleSearch,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search fans by @username or name...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: isDark ? HeyTheme.darkSurface : Colors.white,
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: HeyTheme.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  borderSide: BorderSide(
                    color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                  borderSide: const BorderSide(color: HeyTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // User list
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? Center(
                        child: Text(
                          'No fans found matching "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? HeyTheme.darkTextSecondary : HeyTheme.lightTextSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: displayList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = displayList[index];
                          return InkWell(
                            onTap: () => _openUserProfile(user),
                            borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? HeyTheme.darkSurface : HeyTheme.lightSurface,
                                borderRadius: BorderRadius.circular(HeyTheme.radiusMedium),
                                border: Border.all(
                                  color: isDark ? HeyTheme.darkBorder : HeyTheme.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  HeyAvatar(
                                    photoUrl: user.photoUrl,
                                    name: user.displayName,
                                    radius: 22,
                                    isOnline: user.isOnline,
                                    showPresence: true,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? HeyTheme.darkTextPrimary : HeyTheme.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          '@${user.username}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: HeyTheme.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _openUserProfile(user),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: HeyTheme.primary,
                                      side: const BorderSide(color: HeyTheme.primary, width: 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(HeyTheme.radiusSmall),
                                      ),
                                    ),
                                    child: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
