import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/library_item.dart';
import '../services/library_storage.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'reading_screen.dart';
import 'output_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      /// APP BAR — cream gradient, unchanged from previous shell.
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.creamGradient,
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: const Text(
            "AksharAlly",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),

      /// BODY — blue gradient background, unchanged shell.
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.brandGradientVertical,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spaceLG),
              child: _getScreenForIndex(context),
            ),
          ),
        ),
      ),

      /// BOTTOM NAV — preserved exactly as before.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.creamGradient,
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: currentIndex,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              label: "Library",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _getScreenForIndex(BuildContext context) {
    switch (currentIndex) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return const LibraryScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildDashboard(context);
    }
  }

  // ── DASHBOARD ───────────────────────────────────────────────────────────

  Widget _buildDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dashboardHeader(),
        const SizedBox(height: AppTheme.spaceLG),
        _newReadingCard(context),
        const SizedBox(height: AppTheme.spaceMD),
        _statsCard(),
        const SizedBox(height: AppTheme.spaceLG),
        _continueReadingSection(context),
        const SizedBox(height: AppTheme.spaceLG),
        _libraryLinkCard(),
      ],
    );
  }

  // ── 1. HEADER — time-based greeting ────────────────────────────────────

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Widget _dashboardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _timeBasedGreeting(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          "Welcome Back",
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 2. PRIMARY ACTION — New Reading ────────────────────────────────────

  Widget _newReadingCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLG),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReadingScreen()),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          gradient: AppTheme.brandGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New Reading",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Scan, type, or upload content for dyslexia-friendly reading.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ── 3. STATS — single metric ───────────────────────────────────────────

  Widget _statsCard() {
    final total = LibraryStorage.getItems().length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical: AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentCream,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: const Icon(Icons.auto_stories_outlined,
                color: AppTheme.primaryBlue, size: 22),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text(
            '$total',
            style: AppTheme.headingStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            "Total Readings",
            style: AppTheme.bodyStrongStyle.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  // ── 4. CONTINUE READING ─────────────────────────────────────────────────

  Widget _continueReadingSection(BuildContext context) {
    final items = LibraryStorage.getItems().take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Continue Reading",
          style: AppTheme.titleStyle.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Text(
              "No readings yet — start one above.",
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
          )
        else
          Column(
            children: [
              for (final item in items) ...[
                _continueReadingTile(context, item),
                const SizedBox(height: AppTheme.spaceSM),
              ],
            ],
          ),
      ],
    );
  }

  // Maps sourceType → (icon, friendly label). sourceType values come from
  // LibraryItem as-is: 'image' | 'pdf' | 'docx' | 'text' | 'simplified' |
  // 'unknown' — nothing here modifies LibraryItem/LibraryStorage.
  (IconData, String) _sourceMeta(String sourceType) {
    switch (sourceType) {
      case 'image':
        return (Icons.camera_alt_outlined, 'Image');
      case 'pdf':
        return (Icons.picture_as_pdf_outlined, 'PDF');
      case 'docx':
        return (Icons.description_outlined, 'Document');
      case 'text':
        return (Icons.edit_outlined, 'Typed Text');
      case 'simplified':
        return (Icons.auto_awesome_outlined, 'Simplified Text');
      default:
        return (Icons.menu_book_outlined, 'Document');
    }
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return "$m minute${m == 1 ? '' : 's'} ago";
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return "$h hour${h == 1 ? '' : 's'} ago";
    }
    if (diff.inDays == 1) return "Yesterday";
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _continueReadingTile(BuildContext context, LibraryItem item) {
    final (icon, label) = _sourceMeta(item.sourceType);
    final wordCount =
        item.content.split(' ').where((w) => w.isNotEmpty).length;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OutputScreen(displayText: item.content),
          ),
        );
        if (mounted) setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMD),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.accentCream,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // line 1 — title
                  Text(
                    label,
                    style: AppTheme.bodyStrongStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // line 2 — source/word-count metadata
                  Text(
                    '$label · ${wordCount}w',
                    style: AppTheme.captionStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // line 3 — relative time
                  Text(
                    _relativeTime(item.date),
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 5. LIBRARY LINK ─────────────────────────────────────────────────────

  Widget _libraryLinkCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      onTap: () => setState(() => currentIndex = 1),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical: AppTheme.spaceMD,
        ),
        decoration: BoxDecoration(
          color: AppTheme.accentCream,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          children: [
            const Icon(Icons.book_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: AppTheme.spaceSM),
            const Expanded(
              child: Text(
                "Library",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                  fontSize: 15,
                ),
              ),
            ),
            const Text(
              "View All",
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward, color: AppTheme.primaryBlue, size: 16),
          ],
        ),
      ),
    );
  }
}
