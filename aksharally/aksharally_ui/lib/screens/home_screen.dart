import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/ui_accessibility.dart';
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

  // ── Subscribe to UIAccessibility.notifier ────────────────────────────────
  // When Apply is pressed in SettingsScreen, notifier.value++ fires.
  // Calling setState() here marks this element dirty so build() re-evaluates
  // _bg, _txt, _cardBg, and _ts() immediately — no tab-switch required.
  @override
  void initState() {
    super.initState();
    UIAccessibility.notifier.addListener(_onAccessibilityChanged);
  }

  @override
  void dispose() {
    UIAccessibility.notifier.removeListener(_onAccessibilityChanged);
    super.dispose();
  }

  void _onAccessibilityChanged() {
    if (mounted) setState(() {});
  }

  // ── Derived UIAccessibility helpers ─────────────────────────────────────
  // These are read fresh on every build(), so they respond instantly after Apply.

  /// The applied background colour — drives body container, bottom nav, etc.
  Color get _bg  => UIAccessibility.backgroundColor;
  Color get _txt => UIAccessibility.textColor;

  /// Returns white when the background is dark (low luminance) so cards
  /// always contrast with the page background.
  Color get _cardBg {
    return _bg.computeLuminance() < 0.3
        ? const Color(0xFF2E2E2E)
        : Colors.white;
  }

  Color get _iconChipBg {
    return _bg.computeLuminance() < 0.3
        ? const Color(0xFF3A3A3A)
        : AppTheme.accentCream;
  }

  Color get _mutedTxt {
    return _txt.withOpacity(0.6);
  }

  // ── TextStyle factory (reads UIAccessibility each build) ─────────────────
  TextStyle _ts(double size, FontWeight weight, Color color) =>
      UIAccessibility.previewStyleFor(UIAccessibility.fontFamily).copyWith(
        fontSize:           UIAccessibility.fontSize * (size / 15),
        fontWeight:         UIAccessibility.boldTextEnabled ? FontWeight.bold : weight,
        color:              color,
        letterSpacing:      UIAccessibility.letterSpacing,
        wordSpacing:        UIAccessibility.wordSpacing,
        height:             UIAccessibility.lineHeight,
        fontFamilyFallback: const ['Noto Sans', 'sans-serif'],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      // ── APP BAR — keep brand cream gradient as fixed identity ──────────────
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.creamGradient),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.brandGradient.createShader(bounds),
          child: const Text(
            'AksharAlly',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize:   22,
              color:      Colors.white,
            ),
          ),
        ),
      ),

      // ── BODY — solid colour from UIAccessibility (responds to Apply) ───────
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: _bg,
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

      // ── BOTTOM NAV — background adapts; brand blue kept for active icon ────
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: _bg.computeLuminance() > 0.85
              // Very light bg: use cream gradient to keep the nav visually
              // distinct from the body.
              ? null
              : _bg.withOpacity(0.97),
          gradient: _bg.computeLuminance() > 0.85
              ? AppTheme.creamGradient
              : null,
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset:     const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor:      Colors.transparent,
          elevation:            0,
          currentIndex:         currentIndex,
          selectedItemColor:    AppTheme.primaryBlue,
          unselectedItemColor:  _txt.withOpacity(0.45),
          selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w700),
          onTap: (index) => setState(() => currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon:  Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon:  Icon(Icons.book_outlined),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon:  Icon(Icons.settings_outlined),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getScreenForIndex(BuildContext context) {
    switch (currentIndex) {
      case 0:  return _buildDashboard(context);
      case 1:  return const LibraryScreen();
      case 2:  return const SettingsScreen();
      default: return _buildDashboard(context);
    }
  }

  // ── DASHBOARD ─────────────────────────────────────────────────────────────

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

  // ── 1. HEADER ─────────────────────────────────────────────────────────────

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _dashboardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _timeBasedGreeting(),
          style: _ts(24, FontWeight.w800, _txt),
        ),
        const SizedBox(height: AppTheme.spaceXS),
        Text(
          'Welcome Back',
          style: _ts(15, FontWeight.w500, _mutedTxt),
        ),
      ],
    );
  }

  // ── 2. NEW READING ────────────────────────────────────────────────────────

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
              color:      Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSM),
              decoration: BoxDecoration(
                color:        Colors.white.withOpacity(0.2),
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
                    'New Reading',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Scan, type, or upload content for dyslexia-friendly reading.',
                    style: TextStyle(
                      color:    Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      height:   1.3,
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

  // ── 3. STATS ──────────────────────────────────────────────────────────────

  Widget _statsCard() {
    final total = LibraryStorage.getItems().length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMD,
        vertical:   AppTheme.spaceMD,
      ),
      decoration: BoxDecoration(
        color:        _cardBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        _iconChipBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            ),
            child: Icon(Icons.auto_stories_outlined,
                color: AppTheme.primaryBlue, size: 22),
          ),
          const SizedBox(width: AppTheme.spaceMD),
          Text(
            '$total',
            style: _ts(22, FontWeight.w800, _txt),
          ),
          const SizedBox(width: AppTheme.spaceSM),
          Text(
            'Total Readings',
            style: _ts(14, FontWeight.w500, _mutedTxt),
          ),
        ],
      ),
    );
  }

  // ── 4. CONTINUE READING ───────────────────────────────────────────────────

  Widget _continueReadingSection(BuildContext context) {
    final items = LibraryStorage.getItems().take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Continue Reading',
          style: _ts(16, FontWeight.w700, _txt),
        ),
        const SizedBox(height: AppTheme.spaceSM),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceMD),
            decoration: BoxDecoration(
              color:        _cardBg.withOpacity(0.7),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border:       Border.all(color: _txt.withOpacity(0.1)),
            ),
            child: Text(
              'No readings yet — start one above.',
              style: _ts(14, FontWeight.w400, _mutedTxt),
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

  (IconData, String) _sourceMeta(String sourceType) {
    switch (sourceType) {
      case 'image':      return (Icons.camera_alt_outlined, 'Image');
      case 'pdf':        return (Icons.picture_as_pdf_outlined, 'PDF');
      case 'docx':       return (Icons.description_outlined, 'Document');
      case 'text':       return (Icons.edit_outlined, 'Typed Text');
      case 'simplified': return (Icons.auto_awesome_outlined, 'Simplified Text');
      default:           return (Icons.menu_book_outlined, 'Document');
    }
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m minute${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1)  return 'Yesterday';
    if (diff.inDays < 7)   return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
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
          color:        _cardBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color:        _iconChipBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppTheme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:    _ts(14, FontWeight.w700, _txt),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$label · ${wordCount}w',
                    style:    _ts(12, FontWeight.w400, _mutedTxt),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _relativeTime(item.date),
                    style:    _ts(12, FontWeight.w600, AppTheme.primaryBlue),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _mutedTxt, size: 20),
          ],
        ),
      ),
    );
  }

  // ── 5. LIBRARY LINK ───────────────────────────────────────────────────────

  Widget _libraryLinkCard() {
    final linkBg = _bg.computeLuminance() < 0.3
        ? const Color(0xFF3A3A3A)
        : AppTheme.accentCream;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      onTap: () => setState(() => currentIndex = 1),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMD,
          vertical:   AppTheme.spaceMD,
        ),
        decoration: BoxDecoration(
          color:        linkBg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        child: Row(
          children: [
            Icon(Icons.book_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: AppTheme.spaceSM),
            Expanded(
              child: Text(
                'Library',
                style: _ts(15, FontWeight.w700, _txt),
              ),
            ),
            Text(
              'View All',
              style: _ts(13, FontWeight.w600, AppTheme.primaryBlue),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_forward,
                color: AppTheme.primaryBlue, size: 16),
          ],
        ),
      ),
    );
  }
}
