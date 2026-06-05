import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/screens/profile/profile_screen.dart';
import 'package:learnxchange/screens/sessions/requests_screen.dart';
import 'package:learnxchange/screens/sessions/sessions_screen.dart';
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
    const SessionsScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Sessions'),
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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _submittedQuery = "";
  String _selectedCategory = "";
  double? _minRating;
  final TextEditingController _searchController = TextEditingController();
  final MatchingService _matchingService = MatchingService();
  final UserService _userService = UserService();
  late Stream<UserModel> _userStream;
  Future<List<UserModel>>? _matchFuture;
  UserModel? _lastUser;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _userStream = _userService.getUserData(uid);
  }

  void _performSearch() {
    setState(() {
      _submittedQuery = _searchController.text.trim();
      _matchFuture = null; // Reset future to trigger reload
    });
  }

  Future<List<UserModel>> _getMatches(MatchingService service, UserModel currentUser) {
    if (_matchFuture != null && _lastUser?.uid == currentUser.uid) {
      return _matchFuture!;
    }
    
    _lastUser = currentUser;
    if (_submittedQuery.isEmpty && _selectedCategory.isEmpty && _minRating == null) {
      _matchFuture = service.findMatches(currentUser);
    } else {
      _matchFuture = service.searchUsers(
        query: _submittedQuery,
        category: _selectedCategory,
        minRating: _minRating,
        currentUser: currentUser,
      );
    }
    return _matchFuture!;
  }

  ImageProvider? _getProfileImage(String photoUrl) {
    // ... (rest of the helper)
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: StreamBuilder<UserModel>(
        stream: _userStream,
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text('Are you sure you want to sign out?'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseAuth.instance.signOut();
                          }
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
                  child: Row(
                    children: [
                      Expanded(
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
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _performSearch(),
                            onChanged: (value) {
                              // Only to update UI (like Clear button visibility)
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search for skills or people...',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              icon: GestureDetector(
                                onTap: _performSearch,
                                child: const Icon(Icons.search_rounded, color: Color(0xFF6366F1))
                              ),
                              suffixIcon: _searchController.text.isNotEmpty 
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _submittedQuery = "";
                                        _matchFuture = null;
                                      });
                                    },
                                  ) 
                                : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _showFilterBottomSheet(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _minRating != null ? const Color(0xFF6366F1) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.tune_rounded, 
                            color: _minRating != null ? Colors.white : const Color(0xFF6366F1)
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Section
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Popular Categories',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (_selectedCategory.isNotEmpty)
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedCategory = "";
                                _matchFuture = null;
                              }),
                              child: const Text('Clear', style: TextStyle(color: Colors.grey)),
                            ),
                        ],
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

              // Matching/Search results Logic
              if (currentUser != null)
                FutureBuilder<List<UserModel>>(
                  future: _getMatches(_matchingService, currentUser),
                  builder: (context, matchSnapshot) {
                    String title = 'Recommended for You';
                    if (_submittedQuery.isNotEmpty || _selectedCategory.isNotEmpty || _minRating != null) {
                      title = 'Search Results';
                    } else if (matchSnapshot.hasData && matchSnapshot.data!.isNotEmpty) {
                      title = 'Perfect Matches Found!';
                    }

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
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                if (matchSnapshot.hasData && matchSnapshot.data!.isNotEmpty && _submittedQuery.isEmpty && _selectedCategory.isEmpty && _minRating == null)
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
                                 width: double.infinity,
                                 padding: const EdgeInsets.all(16),
                                 decoration: BoxDecoration(
                                   color: Colors.indigo.withAlpha(10),
                                   borderRadius: BorderRadius.circular(16),
                                 ),
                                 child: Text(
                                   (_submittedQuery.isNotEmpty || _selectedCategory.isNotEmpty || _minRating != null)
                                      ? "No users found matching your search. Try different keywords!"
                                      : "No direct matches found yet. Try adding more skills to your profile!",
                                   textAlign: TextAlign.center,
                                   style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500),
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _minRating = null;
                            _matchFuture = null;
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Minimum Rating',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [1, 2, 3, 4, 5].map((rating) {
                        final isSelected = _minRating == rating.toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(rating.toString()),
                                const SizedBox(width: 4),
                                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _minRating = selected ? rating.toDouble() : null;
                                _matchFuture = null;
                              });
                              setModalState(() {});
                            },
                            selectedColor: const Color(0xFF6366F1).withAlpha(40),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF6366F1) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, Color color) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? "" : label;
          _matchFuture = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: isSelected ? Border.all(color: color, width: 2) : null,
                boxShadow: isSelected ? [
                  BoxShadow(color: color.withAlpha(40), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                color: isSelected ? color : Colors.black87
              ),
            ),
          ],
        ),
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
