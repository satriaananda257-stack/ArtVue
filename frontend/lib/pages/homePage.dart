import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/services/post_service.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/pages/loginPage.dart';
import 'package:frontend/pages/messagePage.dart';
import 'package:frontend/pages/notifPage.dart';
import 'package:frontend/pages/accountPage.dart';
import 'package:frontend/pages/commisPage.dart';
import 'package:frontend/pages/detailPage.dart';
import 'package:frontend/pages/editPostPage.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  int _selectedNav = 0;
  String? _profilePictureUrl;
  String? _selectedCategory;
  int? _myUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadProfile();
    _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    final id = await StorageService.getUserId();
    if (mounted) setState(() => _myUserId = id);
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileService.getMyProfile();
    if (profile != null && mounted) {
      setState(() => _profilePictureUrl = profile['profilePicture']);
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await PostService.getPosts();
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Cannot connect to server';
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> post) async {
    final postId = post['id'] as int;
    final isLiked = post['isLiked'] as bool? ?? false;

    // Optimistic update
    setState(() {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) {
        _posts[idx] = {
          ..._posts[idx],
          'isLiked': !isLiked,
          'likeCount': ((_posts[idx]['likeCount'] as num? ?? 0).toInt()) +
              (isLiked ? -1 : 1),
        };
      }
    });

    final success =
        isLiked ? await PostService.unlikePost(postId) : await PostService.likePost(postId);

    if (!success) {
      // Revert on failure
      setState(() {
        final idx = _posts.indexWhere((p) => p['id'] == postId);
        if (idx != -1) {
          _posts[idx] = {
            ..._posts[idx],
            'isLiked': isLiked,
            'likeCount': ((_posts[idx]['likeCount'] as num? ?? 0).toInt()) +
                (isLiked ? 1 : -1),
          };
        }
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> post) async {
    final postId = post['id'] as int;
    final isFav = post['isFavorite'] as bool? ?? false;

    setState(() {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) {
        _posts[idx] = {..._posts[idx], 'isFavorite': !isFav};
      }
    });

    final success = isFav
        ? await PostService.unfavoritePost(postId)
        : await PostService.favoritePost(postId);

    if (!success) {
      setState(() {
        final idx = _posts.indexWhere((p) => p['id'] == postId);
        if (idx != -1) {
          _posts[idx] = {..._posts[idx], 'isFavorite': isFav};
        }
      });
    }
  }

  void _showPostOptions(Map<String, dynamic> post) {
    final postUserId = post['userId'] as int?;
    final isOwn = postUserId != null && postUserId == _myUserId;
    if (!isOwn) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252840),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: Colors.white70, size: 20),
              title: Text('Edit description',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                final updated = await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => editPostPage(post: post)),
                );
                if (updated != null && mounted) {
                  setState(() {
                    final idx =
                        _posts.indexWhere((p) => p['id'] == updated['id']);
                    if (idx != -1) _posts[idx] = updated;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              title: Text('Delete post',
                  style: GoogleFonts.poppins(
                      color: Colors.redAccent, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeletePost(post);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF252840),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Post',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(Map<String, dynamic> post) async {
    final postId = post['id'] as int;
    final ok = await PostService.deletePost(postId);
    if (ok && mounted) {
      setState(() => _posts.removeWhere((p) => p['id'] == postId));
    } else if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF252840),
          content: Text('Failed to delete post',
              style: GoogleFonts.poppins(
                  color: Colors.white70, fontSize: 13)),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredPosts {
    return _posts.where((p) {
      final matchSearch = _search.isEmpty ||
          (p['title'] ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (p['username'] ?? '').toLowerCase().contains(_search.toLowerCase());
          (p['email'] ?? '').toLowerCase().contains(_search.toLowerCase());
      final matchCategory = _selectedCategory == null ||
          p['category'] == _selectedCategory;
      return matchSearch && matchCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPosts,
          backgroundColor: const Color(0xFF252840),
          color: const Color(0xFFB5FF3A),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFB5FF3A)))
              : _error != null
                  ? _buildError()
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(child: _buildHeader()),
                        _filteredPosts.isEmpty
                            ? SliverFillRemaining(child: _buildEmpty())
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildPostCard(_filteredPosts[index]),
                                  childCount: _filteredPosts.length,
                                ),
                              ),
                      ],
                    ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1A1D2E),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.brush,
                      color: Color(0xFF2ECC71),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Artvue',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Headline
          Text(
            'For the love of human\ncreativity',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF252840),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.poppins(
                    color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    color: Colors.white38, size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Image slider — scrollable horizontal (drag on web, touch on mobile)
          SizedBox(
            height: 110,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _sliderCard(
                    'assets/images/sliderPic1.png',
                    title: 'Made for creators',
                    subtitle: 'Everything you need for vtubing / streaming, music, game, and content adventures - fans welcome too!',
                  ),
                  const SizedBox(width: 10),
                  _sliderCard(
                    'assets/images/sliderPic2.png',
                    title: 'No Generative AI',
                    subtitle: 'Until generative AI is made with Consent, Credit, and Compensation, it is not welcome here.',
                  ),
                  const SizedBox(width: 10),
                  _sliderCard(
                    'assets/images/sliderPic3.png',
                    title: 'Verified but private',
                    subtitle: 'Verified artists, commissions, and reviews, but IRL info stays strictly between you and us.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SizedBox(
            height: 36,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _categoryChip('All', isSelected: _selectedCategory == null),
                  _categoryChip('OC', isSelected: _selectedCategory == 'OC'),
                  _categoryChip('Furry', isSelected: _selectedCategory == 'Furry'),
                  _categoryChip('Fanart', isSelected: _selectedCategory == 'Fanart'),
                  _categoryChip('Anime & Manga', isSelected: _selectedCategory == 'Anime & Manga'),
                  _categoryChip('Digital Art', isSelected: _selectedCategory == 'Digital Art'),
                  _categoryChip('Traditional Art', isSelected: _selectedCategory == 'Traditional Art'),
                  _categoryChip('Illustration', isSelected: _selectedCategory == 'Illustration'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sliderCard(String imagePath, {String? title, String? subtitle}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(
            width: 260,
            height: 110,
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF252840),
                child: const Icon(Icons.image, color: Colors.white24, size: 40),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.72),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          // Text overlay
          if (title != null)
            Positioned(
              left: 10,
              top: 10,
              bottom: 10,
              width: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 9,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _promoCard({
    required String title,
    required String subtitle,
    required Color color,
    required Color accentColor,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, {bool isSelected = false}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = isSelected ? null : (label == 'All' ? null : label);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white54 : const Color(0xFF3A3D52),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _buildPostCard(post);
      },
    );
  }


  Widget _buildPostCard(Map<String, dynamic> post) {
    final username = post['username'] ?? 'Unknown';
    final handle = post['email'] as String? ?? '@${username.toLowerCase().replaceAll(' ', '_')}';
    final title = post['title'] ?? '';
    final description = post['description'] ?? '';
    final imageUrl = post['imageUrl'] as String?;
    final authorPic = post['profilePicture'] as String?;
    final likeCount = (post['likeCount'] as num? ?? 0).toInt();
    final commentCount = (post['commentCount'] as num? ?? 0).toInt();
    final isLiked = post['isLiked'] as bool? ?? false;
    final isFavorite = post['isFavorite'] as bool? ?? false;

    return GestureDetector(
      onTap: () async {
        // Navigate to detail page and get back updated post
        final updated = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(builder: (_) => detailPage(post: post)),
        );
        if (updated != null && mounted) {
          setState(() {
            final idx = _posts.indexWhere((p) => p['id'] == updated['id']);
            if (idx != -1) _posts[idx] = updated;
          });
        }
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
      color: const Color(0xFF1A1D2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: Row(
              children: [
                // Profile picture — guestProfile as default
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: authorPic != null && authorPic.isNotEmpty
                        ? Image.network(
                            authorPic,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/images/guestProfile.png',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/images/guestProfile.png',
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        handle,
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white70, size: 20),
                  onPressed: () => _showPostOptions(post),
                ),
              ],
            ),
          ),

          // Image — aspect ratio mengikuti gambar asli, max 500px
          if (imageUrl != null && imageUrl.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        height: 200,
                        color: const Color(0xFF252840),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFB5FF3A), strokeWidth: 2),
                        ),
                      ),
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: const Color(0xFF252840),
                  child: const Icon(Icons.broken_image,
                      color: Colors.white24, size: 48),
                ),
              ),
            )
          else
            Container(
              height: 180,
              color: const Color(0xFF252840),
              child: const Center(
                child:
                    Icon(Icons.image, color: Color(0xffececec), size: 48),
              ),
            ),

          const SizedBox(height: 8),

          // Actions row — like (pill), comment (pill), bookmark (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                // Like pill
                GestureDetector(
                  onTap: () => _toggleLike(post),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252840),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          isLiked
                              ? 'assets/icons/ant-design--heart-filled.svg'
                              : 'assets/icons/ant-design--heart-outlined.svg',
                          width: 18,
                          height: 18,
                          theme: SvgTheme(
                            currentColor: isLiked
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likeCount',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Comment pill
                GestureDetector(
                  onTap: () async {
                    final updated =
                        await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => detailPage(post: post)),
                    );
                    if (updated != null && mounted) {
                      setState(() {
                        final idx = _posts
                            .indexWhere((p) => p['id'] == updated['id']);
                        if (idx != -1) _posts[idx] = updated;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252840),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/comment.svg',
                          width: 18,
                          height: 18,
                          theme: const SvgTheme(currentColor: Colors.white70),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$commentCount',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Bookmark
                GestureDetector(
                  onTap: () => _toggleFavorite(post),
                  child: SvgPicture.asset(
                    isFavorite
                        ? 'assets/icons/bookmark_filled.svg'
                        : 'assets/icons/bookmark_outline.svg',
                    width: 22,
                    height: 22,
                    theme: SvgTheme(
                      currentColor: isFavorite ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title + description
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Color(0xffececec),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06)),
        ],
      ),
    ),  // closes GestureDetector child: Container
    );  // closes GestureDetector
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadPosts,
            child: Text('Retry',
                style: GoogleFonts.poppins(color: const Color(0xFFECECEC))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No posts yet',
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14),
      ),
    );
  }

  Widget _buildBottomNav() {
    // Nav items: [svgAsset or null for image button, label]
    final navItems = [
      {'svg': 'assets/icons/home.svg'},
      {'svg': 'assets/icons/bell.svg'},
      {'svg': 'assets/icons/message.svg'},
      {'svg': 'assets/icons/sparkles.svg'},
      {'img': 'profile'}, // profile picture button
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F1A),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (i) {
          final active = i == _selectedNav;
          final item = navItems[i];

          Widget iconWidget;

          if (item.containsKey('img')) {
            // Custom image button (smiley face)
            iconWidget = Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: active
                    ? Border.all(color: const Color(0xFFececec), width: 2)
                    : null,
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
                    : Image.asset(
                        'assets/images/guestProfile.png',
                        fit: BoxFit.cover,
                      ),
              ),
            );
          } else {
            // SVG icon
            iconWidget = SvgPicture.asset(
              item['svg']!,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                active ? const Color(0xFFececec) : Colors.white38,
                BlendMode.srcIn,
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              if (i == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const notifPage()));
                return;
              }
              if (i == 2) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const messagePage()));
                return;
              }
              if (i == 3) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const commisPage()));
                return;
              }
              if (i == 4) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const accountPage()));
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

  Future<void> _logout() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const loginPage()),
    );
  }
}
