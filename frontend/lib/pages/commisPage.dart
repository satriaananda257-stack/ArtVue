import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class commisPage extends StatefulWidget {
  const commisPage({super.key});

  @override
  State<commisPage> createState() => _commisPageState();
}

class _commisPageState extends State<commisPage> {
  int _selectedTab = 0;

  final List<String> _tabs = ['All', 'Pending', 'Accepted', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  // Tabs
                  ...List.generate(_tabs.length, (i) {
                    final active = i == _selectedTab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = i),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tabs[i],
                              style: GoogleFonts.poppins(
                                color: active ? Colors.white : Colors.white38,
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),

                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),

            // Empty state
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/commisPic.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.star_outline,
                        color: Color(0xFF4A5080),
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Send your first request!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All of your ongoing and past commissions\nwill show up here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
