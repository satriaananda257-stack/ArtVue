import 'package:flutter/material.dart';
import 'package:frontend/pages/homePage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/pages/createPostPage.dart';
import 'package:frontend/pages/loginPage.dart';
import 'package:frontend/pages/commisPage.dart';
import 'package:frontend/pages/messagePage.dart';
import 'package:frontend/pages/notifPage.dart';

class accountPage extends StatefulWidget {
  const accountPage({super.key});

  @override
  State<accountPage> createState() => _accountPageState();
}

class _accountPageState extends State<accountPage> {
  int _selectedNav = 4;
  int _selectedTab = 0;

  // Profile data
  String? _username;
  String? _email;
  String? _bio;
  String? _profilePictureUrl;
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;

  // Tab data
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _saved = [];
  List<Map<String, dynamic>> _liked = [];
  bool _tabLoading = false;

  final List<String> _tabs = ['Posts', 'Saved', 'Liked'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final username = await StorageService.getUsername();
    final email = await StorageService.getEmail();
    setState(() {
      _username = username;
      _email = email;
    });

    final profile = await ProfileService.getMyProfile();
    if (profile != null && mounted) {
      setState(() {
        _username = profile['username'] ?? username;
        _bio = profile['bio'];
        _profilePictureUrl = profile['profilePicture'];
        _followersCount = (profile['followersCount'] as num? ?? 0).toInt();
        _followingCount = (profile['followingCount'] as num? ?? 0).toInt();
        _postsCount = (profile['postsCount'] as num? ?? 0).toInt();
      });
      _loadTab(0);
    }
  }

  Future<void> _loadTab(int tabIndex) async {
    setState(() => _tabLoading = true);
    switch (tabIndex) {
      case 0:
        final posts = await ProfileService.getMyPosts();
        if (mounted) setState(() { _posts = posts; _tabLoading = false; });
        break;
      case 1:
        final saved = await ProfileService.getMySaved();
        if (mounted) setState(() { _saved = saved; _tabLoading = false; });
        break;
      case 2:
        final liked = await ProfileService.getMyLiked();
        if (mounted) setState(() { _liked = liked; _tabLoading = false; });
        break;
    }
  }

  List<Map<String, dynamic>> get _currentTabData {
    switch (_selectedTab) {
      case 0: return _posts;
      case 1: return _saved;
      case 2: return _liked;
      default: return [];
    }
  }

  Future<void> _logout() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const loginPage()),
      (_) => false,
    );
  }

  // ── EDIT PROFILE DIALOG ────────────────────────────────────
  void _showEditProfile() {
    final usernameCtrl = TextEditingController(text: _username ?? '');
    final bioCtrl = TextEditingController(text: _bio ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF252840),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Profile',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(usernameCtrl, 'Username'),
              const SizedBox(height: 12),
              _dialogField(bioCtrl, 'Bio', maxLines: 3),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.white54)),
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      setStateDialog(() => saving = true);
                      final updated = await ProfileService.updateMyProfile(
                        username: usernameCtrl.text.trim(),
                        bio: bioCtrl.text.trim(),
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (updated != null && mounted) {
                        setState(() {
                          _username = updated['username'] ?? _username;
                          _bio = updated['bio'];
                        });
                        await StorageService.saveAuth(
                          token: (await StorageService.getToken())!,
                          userId: (await StorageService.getUserId())!,
                          email: _email!,
                          username: _username,
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFFB5FF3A), strokeWidth: 2),
                    )
                  : Text('Save',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFFB5FF3A),
                          fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1D2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3D52)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF3A3D52)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFB5FF3A)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  // ── PROFILE PICTURE WIDGET ─────────────────────────────────
  Widget _buildProfilePicture({double size = 80}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1A1D2E), width: 3),
      ),
      child: ClipOval(
        child: _profilePictureUrl != null && _profilePictureUrl!.isNotEmpty
            ? Image.network(
                _profilePictureUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/guestProfile.png',
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset('assets/images/guestProfile.png', fit: BoxFit.cover),
      ),
    );
  }

  // ── POST GRID ───────────────────────────────────────────────
  Widget _buildPostGrid(List<Map<String, dynamic>> posts) {
    if (_tabLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
            child: CircularProgressIndicator(
                color: Color(0xFFB5FF3A), strokeWidth: 2)),
      );
    }
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No ${_tabs[_selectedTab].toLowerCase()} yet',
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) {
        final post = posts[i];
        final imageUrl = post['imageUrl'] as String?;
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF252840),
                    child: const Icon(Icons.image,
                        color: Colors.white24, size: 24),
                  ),
                )
              : Container(
                  color: const Color(0xFF252840),
                  child: const Icon(Icons.image,
                      color: Colors.white24, size: 24),
                ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── BANNER ──────────────────────────────
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 120,
                          child: Image.asset(
                            'assets/images/guestBanner.webp',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Container(color: const Color(0xFF252840)),
                          ),
                        ),
                        Positioned(
                          bottom: -40,
                          left: 16,
                          child: Stack(
                            children: [
                              _buildProfilePicture(size: 80),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      'assets/icons/pencil.svg',
                                      width: 14,
                                      height: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const createPostPage()),
                            ).then((result) {
                              if (result == true) _loadTab(0);
                            }),
                            child: SvgPicture.asset(
                              'assets/icons/plus.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _logout,
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedLogoutCircle01,
                              color: Color(0xFFFFFFFF),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // ── USER INFO ────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username ?? 'Username',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_email != null) ...[
                            const SizedBox(height: 2),
                            Text(_email!,
                                style: GoogleFonts.poppins(
                                    color: Colors.white54, fontSize: 13)),
                          ],
                          if (_bio != null && _bio!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(_bio!,
                                style: GoogleFonts.poppins(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                          const SizedBox(height: 14),

                          // Edit profile button
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: _showEditProfile,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Color(0xFF3A3D52)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Edit profile',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Followers / Following / Posts counts
                          Row(
                            children: [
                              Expanded(
                                child: _statButton(
                                    'Followers', _followersCount),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statButton(
                                    'Following', _followingCount),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statButton('Posts', _postsCount),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ── TABS ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(_tabs.length, (i) {
                          final active = i == _selectedTab;
                          return GestureDetector(
                            onTap: () {
                              if (_selectedTab != i) {
                                setState(() => _selectedTab = i);
                                _loadTab(i);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24),
                              child: Column(
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: GoogleFonts.poppins(
                                      color: active
                                          ? Colors.white
                                          : Colors.white38,
                                      fontSize: 14,
                                      fontWeight: active
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (active)
                                    Container(
                                      height: 2,
                                      width: 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.08)),

                    // ── TAB CONTENT ──────────────────────────
                    _buildPostGrid(_currentTabData),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _statButton(String label, int count) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF3A3D52)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        '$label  $count',
        style: GoogleFonts.poppins(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final navItems = [
      {'svg': 'assets/icons/home.svg'},
      {'svg': 'assets/icons/bell.svg'},
      {'svg': 'assets/icons/message.svg'},
      {'svg': 'assets/icons/sparkles.svg'},
      {'img': 'profile'},
    ];

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F1A),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
          final active = i == _selectedNav;
          final item = navItems[i];

          Widget iconWidget;
          if (item.containsKey('img')) {
            iconWidget = Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: active
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              child: ClipOval(
                child: _profilePictureUrl != null &&
                        _profilePictureUrl!.isNotEmpty
                    ? Image.network(_profilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                            'assets/images/guestProfile.png',
                            fit: BoxFit.cover))
                    : Image.asset('assets/images/guestProfile.png',
                        fit: BoxFit.cover),
              ),
            );
          } else {
            iconWidget = SvgPicture.asset(
              item['svg']!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                active ? Colors.white : Colors.white38,
                BlendMode.srcIn,
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              if (i == 1) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const notifPage()));
                return;
              }
              if (i == 2) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const messagePage()));
                return;
              }
              if (i == 3) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const commisPage()));
                return;
              }
              if (i == 0) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const homePage()));
                return;
              }
              setState(() => _selectedNav = i);
            },
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 48,
              height: 64,
              child: Center(child: iconWidget),
            ),
          );
        }),
      ),
    );
  }
}
