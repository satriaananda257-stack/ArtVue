import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/post_service.dart';
import 'package:frontend/services/profile_service.dart';
import 'package:frontend/services/storage_service.dart';

class detailPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const detailPage({super.key, required this.post});

  @override
  State<detailPage> createState() => _detailPageState();
}

class _detailPageState extends State<detailPage> {
  late Map<String, dynamic> _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingComments = true;
  bool _submitting = false;
  bool _followLoading = false;
  int? _myUserId;

  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _post = Map<String, dynamic>.from(widget.post);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    _myUserId = await StorageService.getUserId();
    await Future.wait([
      _loadComments(),
      _loadFollowStatus(),
    ]);
  }

  Future<void> _loadFollowStatus() async {
    final authorId = _post['userId'] as int?;
    if (authorId == null || authorId == _myUserId) return;
    final profile = await ProfileService.getUserProfile(authorId);
    if (profile != null && mounted) {
      setState(() {
        _post = {
          ..._post,
          'isFollowing': profile['isFollowing'] as bool? ?? false,
        };
      });
    }
  }

  Future<void> _loadComments() async {
    final postId = _post['id'] as int;
    setState(() => _loadingComments = true);
    final comments = await PostService.getComments(postId);
    if (mounted) setState(() {
      _comments = comments;
      _loadingComments = false;
    });
  }

  // ── LIKE ──────────────────────────────────────────────────
  Future<void> _toggleLike() async {
    final postId = _post['id'] as int;
    final isLiked = _post['isLiked'] as bool? ?? false;
    setState(() {
      _post = {
        ..._post,
        'isLiked': !isLiked,
        'likeCount': ((_post['likeCount'] as num? ?? 0).toInt()) + (isLiked ? -1 : 1),
      };
    });
    final ok = isLiked
        ? await PostService.unlikePost(postId)
        : await PostService.likePost(postId);
    if (!ok && mounted) {
      setState(() {
        _post = {
          ..._post,
          'isLiked': isLiked,
          'likeCount': ((_post['likeCount'] as num? ?? 0).toInt()) + (isLiked ? 1 : -1),
        };
      });
    }
  }

  // ── FAVORITE ──────────────────────────────────────────────
  Future<void> _toggleFavorite() async {
    final postId = _post['id'] as int;
    final isFav = _post['isFavorite'] as bool? ?? false;
    setState(() => _post = {..._post, 'isFavorite': !isFav});
    final ok = isFav
        ? await PostService.unfavoritePost(postId)
        : await PostService.favoritePost(postId);
    if (!ok && mounted) setState(() => _post = {..._post, 'isFavorite': isFav});
  }

  // ── FOLLOW ────────────────────────────────────────────────
  bool get _isOwnPost {
    final postUserId = _post['userId'] as int?;
    return postUserId != null && postUserId == _myUserId;
  }

  Future<void> _toggleFollow() async {
    final authorId = _post['userId'] as int?;
    if (authorId == null) return;
    final isFollowing = _post['isFollowing'] as bool? ?? false;
    setState(() {
      _followLoading = true;
      _post = {..._post, 'isFollowing': !isFollowing};
    });
    final ok = isFollowing
        ? await ProfileService.unfollowUser(authorId)
        : await ProfileService.followUser(authorId);
    if (!ok && mounted) {
      setState(() => _post = {..._post, 'isFollowing': isFollowing});
    }
    if (mounted) setState(() => _followLoading = false);
  }

  // ── SUBMIT COMMENT ────────────────────────────────────────
  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    final postId = _post['id'] as int;
    final newComment = await PostService.addComment(postId, text);
    if (mounted) {
      setState(() {
        _submitting = false;
        if (newComment != null) {
          _commentCtrl.clear();
          _comments = [newComment, ..._comments];
          _post = {
            ..._post,
            'commentCount': ((_post['commentCount'] as num? ?? 0).toInt()) + 1,
          };
        } else {
          // show snackbar on failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF252840),
              content: Text(
                'Gagal kirim komentar. Coba lagi.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
            ),
          );
        }
      });
    }
  }

  // ── DELETE COMMENT ────────────────────────────────────────
  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final commentId = comment['id'] as int;
    final commentUserId = comment['userId'] as int?;
    if (commentUserId != _myUserId) return;
    final ok = await PostService.deleteComment(commentId);
    if (ok && mounted) {
      setState(() {
        _comments.removeWhere((c) => c['id'] == commentId);
        _post = {
          ..._post,
          'commentCount': ((_post['commentCount'] as num? ?? 0).toInt()) - 1,
        };
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorRow(),
                  _buildImage(),
                  _buildActions(),
                  _buildTitleDesc(),
                  _buildTutorialSteps(),
                  const Divider(height: 1, color: Color(0x14FFFFFF)),
                  _buildCommentsSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS
  // ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1D2E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
        onPressed: () => Navigator.pop(context, _post),
      ),
      title: Text(
        'Post',
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: Icon(
            (_post['isFavorite'] as bool? ?? false) ? Icons.bookmark : Icons.bookmark_border,
            color: (_post['isFavorite'] as bool? ?? false) ? Colors.white : Colors.white60,
            size: 22,
          ),
          onPressed: _toggleFavorite,
        ),
      ],
    );
  }

  Widget _buildAuthorRow() {
    final username = _post['username'] ?? 'Unknown';
    final handle = _post['email'] as String? ?? '@${username.toLowerCase().replaceAll(' ', '_')}';
    final authorPic = _post['profilePicture'] as String?;
    final isFollowing = _post['isFollowing'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: authorPic != null && authorPic.isNotEmpty
                  ? Image.network(
                      authorPic,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Image.asset('assets/images/guestProfile.png', fit: BoxFit.cover),
                    )
                  : Image.asset('assets/images/guestProfile.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(handle,
                    style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          // Follow button — only shown if not own post
          if (!_isOwnPost)
            GestureDetector(
              onTap: _followLoading ? null : _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.transparent : const Color(0xFFB5FF3A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isFollowing ? const Color(0xFF3A3D52) : const Color(0xFFB5FF3A),
                  ),
                ),
                child: _followLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2),
                      )
                    : Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: GoogleFonts.poppins(
                          color: isFollowing ? Colors.white60 : Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = _post['imageUrl'] as String?;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 240,
        color: const Color(0xFF252840),
        child: const Center(
            child: Icon(Icons.image, color: Colors.white24, size: 56)),
      );
    }
    return Image.network(
      imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              height: 240,
              color: const Color(0xFF252840),
              child: const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFB5FF3A), strokeWidth: 2)),
            ),
      errorBuilder: (_, _, _) => Container(
        height: 240,
        color: const Color(0xFF252840),
        child: const Center(
            child: Icon(Icons.broken_image, color: Colors.white24, size: 56)),
      ),
    );
  }

  Widget _buildActions() {
    final isLiked = _post['isLiked'] as bool? ?? false;
    final likeCount = (_post['likeCount'] as num? ?? 0).toInt();
    final commentCount = (_post['commentCount'] as num? ?? 0).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      child: Row(
        children: [
          // Like
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white60,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Text('$likeCount',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Comment count (non-interactive, scroll handled by field below)
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.white60, size: 20),
              const SizedBox(width: 4),
              Text('$commentCount',
                  style: GoogleFonts.poppins(
                      color: Colors.white60, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleDesc() {
    final title = _post['title'] ?? '';
    final description = _post['description'] ?? '';
    final category = _post['category'] as String?;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null && category.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(category,
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 11)),
            ),
          Text(title,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(description,
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 13, height: 1.6)),
          ],
        ],
      ),
    );
  }

  // ── TUTORIAL STEPS (hardcoded, static) ────────────────────

  static const List<Map<String, String>> _tutorialSteps = [
    {
      'step': 'Step 1 — Make a Rough Sketch',
      'image': 'assets/images/step_sketch.png',
      'desc':
          'Start by drawing a simple rough sketch to determine the character\'s pose and proportions. Don\'t worry about making the lines perfect at this stage.',
    },
    {
      'step': 'Step 2 — Create the Line Art',
      'image': 'assets/images/step_lineart.png',
      'desc':
          'Once the sketch is ready, create clean line art by following the important shapes and details from the sketch.',
    },
    {
      'step': 'Step 3 — Add Base Colors',
      'image': 'assets/images/step_coloring.png',
      'desc':
          'Choose a color palette that matches the character\'s design, then apply the base colors to the hair, skin, clothes, and other elements.',
    },
    {
      'step': 'Step 4 — Add Shadows and Details',
      'image': 'assets/images/step_shading.png',
      'desc':
          'Add shadows, highlights, and small details to make the illustration look more dimensional and interesting.',
    },
    {
      'step': 'Step 5 — Finalize the Artwork',
      'image': 'assets/images/step_final.png',
      'desc':
          'Clean up any unnecessary elements and make the final adjustments to the colors, lighting, and details.',
    },
  ];

  Widget _buildTutorialSteps() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro text
          Text(
            'Learn how to create a simple character illustration from a basic sketch to the final artwork.',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Steps
          ..._tutorialSteps.asMap().entries.map((entry) {
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step title
                  Text(
                    step['step']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Step image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      step['image']!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252840),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.image_outlined,
                                  color: Colors.white24, size: 36),
                              const SizedBox(height: 6),
                              Text(
                                step['image']!.split('/').last,
                                style: GoogleFonts.poppins(
                                    color: Colors.white24, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Step description
                  Text(
                    step['desc']!,
                    style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (_loadingComments)
            const Center(
                child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                  color: Color(0xFFB5FF3A), strokeWidth: 2),
            ))
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No comments yet',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 13)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0x0FFFFFFF)),
              itemBuilder: (_, i) => _buildCommentItem(_comments[i]),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final username = comment['username'] ?? 'User';
    final text = comment['comment'] ?? '';
    final commentUserId = comment['userId'] as int?;
    final isOwn = commentUserId != null && commentUserId == _myUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF252840),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset('assets/images/guestProfile.png',
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(text,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 12, height: 1.5)),
              ],
            ),
          ),
          if (isOwn)
            GestureDetector(
              onTap: () => _confirmDeleteComment(comment),
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.delete_outline,
                    color: Colors.white24, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F1A),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF252840),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _commentCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submitting ? null : _submitComment,
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFB5FF3A),
                shape: BoxShape.circle,
              ),
              child: _submitting
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(Map<String, dynamic> comment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF252840),
        title: Text('Delete comment',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
        content: Text('Are you sure?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
