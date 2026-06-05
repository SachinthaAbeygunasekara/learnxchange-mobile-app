import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/screens/profile/profile_screen.dart';
import 'package:learnxchange/screens/sessions/requests_screen.dart';
import 'package:learnxchange/screens/chat/chat_list_screen.dart';
import 'package:learnxchange/services/matching_service.dart';
import 'package:learnxchange/services/user_service.dart';
import 'package:learnxchange/services/request_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeView(),
    const ChatListScreen(),
    const RequestsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_horiz_rounded), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  ImageProvider? _getProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final matchingService = MatchingService();

    return SafeArea(
      child: StreamBuilder<UserModel>(
        stream: UserService().getUserData(firebaseUser?.uid ?? ''),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final currentUser = userSnapshot.data;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${currentUser?.name.split(' ')[0] ?? 'User'}!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Discover Skills',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withAlpha(50), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: currentUser != null ? _getProfileImage(currentUser.photoUrl) : null,
                            child: (currentUser == null || currentUser.photoUrl.isEmpty) 
                                ? const Icon(Icons.logout_rounded, color: Color(0xFF6366F1)) 
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for skills or people...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        icon: const Icon(Icons.search_rounded, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // Categories Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        'Popular Categories',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildCategoryItem(Icons.code_rounded, 'Coding', const Color(0xFF6366F1)),
                          _buildCategoryItem(Icons.brush_rounded, 'Design', const Color(0xFFEC4899)),
                          _buildCategoryItem(Icons.language_rounded, 'Language', const Color(0xFFF59E0B)),
                          _buildCategoryItem(Icons.music_note_rounded, 'Music', const Color(0xFF10B981)),
                          _buildCategoryItem(Icons.camera_alt_rounded, 'Photo', const Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Matching Logic
              if (currentUser != null)
                FutureBuilder<List<UserModel>>(
                  future: matchingService.findMatches(currentUser),
                  builder: (context, matchSnapshot) {
                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  matchSnapshot.hasData && matchSnapshot.data!.isNotEmpty 
                                    ? 'Perfect Matches Found!' 
                                    : 'Recommended for You',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                if (matchSnapshot.hasData && matchSnapshot.data!.isNotEmpty)
                                  const Text(
                                    'See All',
                                    style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          
                          if (matchSnapshot.connectionState == ConnectionState.waiting)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                          else if (matchSnapshot.hasError)
                            Center(child: Text("Error loading matches: ${matchSnapshot.error}"))
                          else if (!matchSnapshot.hasData || matchSnapshot.data!.isEmpty)
                             Padding(
                               padding: const EdgeInsets.all(24.0),
                               child: Container(
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Colors.indigo.withAlpha(10),
                                   borderRadius: BorderRadius.circular(16),
                                 ),
                                 child: const Text(
                                   "No direct matches found yet. Try adding more skills to your profile!",
                                   textAlign: TextAlign.center,
                                   style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
                                 ),
                               ),
                             )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: matchSnapshot.data!.length,
                              itemBuilder: (context, index) {
                                final match = matchSnapshot.data![index];
                                return _MatchCard(
                                  match: match,
                                  currentUser: currentUser,
                                  theme: theme,
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        }
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatefulWidget {
  final UserModel match;
  final UserModel currentUser;
  final ThemeData theme;

  const _MatchCard({
    required this.match,
    required this.currentUser,
    required this.theme,
  });

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _isSending = false;

  ImageProvider? _getProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      try {
        final base64String = photoUrl.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        return null;
      }
    }
    return NetworkImage(photoUrl);
  }

  Future<void> _sendRequest(String skillOffered, String skillWanted) async {
    setState(() => _isSending = true);
    try {
      await RequestService().sendRequest(
        sender: widget.currentUser,
        receiver: widget.match,
        skillOffered: skillOffered,
        skillWanted: skillWanted,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${widget.match.name}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find specific skill match for display
    final matchingOffered = widget.match.offeredSkills.firstWhere(
      (s) => widget.currentUser.wantedSkills.contains(s),
      orElse: () => widget.match.offeredSkills.first,
    );
    final matchingWanted = widget.match.wantedSkills.firstWhere(
      (s) => widget.currentUser.offeredSkills.contains(s),
      orElse: () => widget.match.wantedSkills.first,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: widget.match.uid),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: _getProfileImage(widget.match.photoUrl),
                  child: widget.match.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.match.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.match.rating.toStringAsFixed(1),
                            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${widget.match.ratingCount})',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border_rounded, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _buildSkillBadge('Offers', matchingOffered, const Color(0xFF6366F1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: Colors.grey, size: 20),
              ),
              _buildSkillBadge('Wants', matchingWanted, const Color(0xFFEC4899)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSending ? null : () => _sendRequest(matchingWanted, matchingOffered),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Send Exchange Request', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBadge(String title, String skill, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            skill,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
