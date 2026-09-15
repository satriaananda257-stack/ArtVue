import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/services/post_service.dart';

class editPostPage extends StatefulWidget {
  final Map<String, dynamic> post;

  const editPostPage({super.key, required this.post});

  @override
  State<editPostPage> createState() => _editPostPageState();
}

class _editPostPageState extends State<editPostPage> {
  late final TextEditingController _descCtrl;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.post['description'] ?? '');
    _descCtrl.addListener(() {
      final changed = _descCtrl.text.trim() != (widget.post['description'] ?? '').trim();
      if (changed != _changed) setState(() => _changed = changed);
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newDesc = _descCtrl.text.trim();
    if (!_changed) return;

    setState(() => _saving = true);
    final postId = widget.post['id'] as int;
    final ok = await PostService.updatePostDescription(postId, newDesc);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      final updated = {...widget.post, 'description': newDesc};
      Navigator.pop(context, updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF252840),
          content: Text(
            'Failed to save. Try again.',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Post',
          style: GoogleFonts.poppins(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: (_changed && !_saving) ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Color(0xFFB5FF3A), strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        color: _changed
                            ? const Color(0xFFB5FF3A)
                            : Colors.white24,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post preview (image + title — read only)
            _buildPostPreview(),
            const SizedBox(height: 24),

            // Description field
            Text(
              'Description',
              style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252840),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _changed
                      ? const Color(0xFFB5FF3A).withValues(alpha: 0.5)
                      : const Color(0xFF3A3D52),
                ),
              ),
              child: TextField(
                controller: _descCtrl,
                maxLines: 6,
                style:
                    GoogleFonts.poppins(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Write a description...',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descCtrl.text.length} chars',
                style: GoogleFonts.poppins(
                    color: Colors.white24, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostPreview() {
    final title = widget.post['title'] ?? '';
    final imageUrl = widget.post['imageUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252840),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1A1D2E),
                  child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white24, size: 40)),
                ),
              ),
            ),
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
