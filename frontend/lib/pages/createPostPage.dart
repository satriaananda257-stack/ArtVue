import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/services/post_service.dart';

class createPostPage extends StatefulWidget {
  const createPostPage({super.key});

  @override
  State<createPostPage> createState() => _createPostPageState();
}

class _createPostPageState extends State<createPostPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _loading = false;
  String? _error;

  final List<String> _categories = [
    'OC', 'Furry', 'Fanart', 'Anime & Manga',
    'Digital Art', 'Traditional Art', 'Illustration',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Tidak bisa membuka galeri. Pastikan izin diberikan.');
      }
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Title tidak boleh kosong');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Description tidak boleh kosong');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final success = await PostService.createPost(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _selectedCategory,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, true); // true = refresh
      } else {
        setState(() => _error = 'Gagal membuat post');
      }
    } catch (e) {
      setState(() => _error = 'Cannot connect to server');
    } finally {
      if (mounted) setState(() => _loading = false);
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
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create Post', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFB5FF3A), strokeWidth: 2))
                : Text('Post', style: GoogleFonts.poppins(color: const Color(0xFFB5FF3A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade900.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: GoogleFonts.poppins(color: Colors.red.shade300, fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF252840),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3A3D52)),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: Colors.white38, size: 48),
                          const SizedBox(height: 8),
                          Text('Tap to add image', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 13)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text('Title', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            _buildField(_titleCtrl, 'Enter title...'),
            const SizedBox(height: 14),

            // Description
            Text('Description', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            _buildField(_descCtrl, 'Enter description...', maxLines: 4),
            const SizedBox(height: 14),

            // Category
            Text('Category', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = selected ? null : cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFB5FF3A).withValues(alpha: 0.15) : const Color(0xFF252840),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? const Color(0xFFB5FF3A) : const Color(0xFF3A3D52)),
                    ),
                    child: Text(cat, style: GoogleFonts.poppins(color: selected ? const Color(0xFFB5FF3A) : Colors.white54, fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF252840),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3A3D52))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3A3D52))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFB5FF3A))),
      ),
    );
  }
}
