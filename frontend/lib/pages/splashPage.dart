import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/pages/registerPage.dart';
import 'package:frontend/pages/loginPage.dart';

class splashPage extends StatefulWidget {
  const splashPage({super.key});

  @override
  State<splashPage> createState() => _splashPageState();
}

class _splashPageState extends State<splashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Phase 1: logo + name fade in
    _controller.forward();

    // Phase 2: after 2.5s, switch to welcome screen
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _controller.reverse().then((_) {
        if (!mounted) return;
        setState(() => _showWelcome = true);
        _controller.forward();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2130),
      body: FadeTransition(
        opacity: _fade,
        child: _showWelcome ? _buildWelcome(context) : _buildLogo(),
      ),
    );
  }

  // ── Logo screen ────────────────────────────────────────────
  Widget _buildLogo() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 52,
            height: 52,
          ),
          const SizedBox(width: 12),
          Text(
            'Artvue',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome screen ─────────────────────────────────────────
  Widget _buildWelcome(BuildContext context) {
    return Column(
      children: [
        // Top: hero image + quote
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/splashHero.png',
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28.0, vertical: 48),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Whether you're an artist or an art enthusiast,\nArtVue gives you a space to explore, create,\nand be inspired.",
                    style: GoogleFonts.reenieBeanie(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom: CTA panel
        Container(
          width: double.infinity,
          color: const Color(0xFF1E2130),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to ArtVue',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 12),
                  children: [
                    const TextSpan(text: 'By tapping Accept, you agree to '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB5FF3A),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFB5FF3A),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const registerPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB5FF3A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Create new account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const loginPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3347),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Sign in',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
