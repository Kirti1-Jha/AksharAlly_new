import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'reader_screen.dart';
import 'library_screen.dart';
import 'settings_screen.dart';
import 'enter_text_screen.dart';
import 'upload_file_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  static const blueGradient = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  static const creamGradient = [
    Color(0xFFFFF3E0),
    Color(0xFFFFE0B2),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      /// 🔥 APP BAR (FIXED CREAM GRADIENT)
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: creamGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        /// 🔥 GRADIENT TEXT TITLE
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: blueGradient,
          ).createShader(bounds),
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

      /// 🔥 BODY (BLUE BACKGROUND)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: blueGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _getScreenForIndex(context),
              ),
            ),
          ),
        ),
      ),

      /// 🔥 NAV BAR (CREAM GRADIENT FIX)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: creamGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFF1565C0),
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
        return _buildHomeContent(context);
      case 1:
        return const LibraryScreen();
      case 2:
        return const SettingsScreen();
      default:
        return _buildHomeContent(context);
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        const Text(
          "Welcome Back!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 30),

        _actionCard(
          context,
          icon: Icons.document_scanner_outlined,
          title: "Scan the Image",
          subtitle: "Capture text using camera",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReaderScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 15),

        _actionCard(
          context,
          icon: Icons.edit_outlined,
          title: "Enter Text",
          subtitle: "Type text manually",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const EnterTextScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 15),

        _actionCard(
          context,
          icon: Icons.upload_file_outlined,
          title: "Upload File",
          subtitle: "Import image or document",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UploadFileScreen(),
              ),
            );
          },
        ),

        const SizedBox(height: 15),

        _actionCard(
          context,
          icon: Icons.menu_book_outlined,
          title: "Continue Reading",
          subtitle: "Resume previous session",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No saved reading yet"),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF1565C0)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}