import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class UploadFileScreen extends StatefulWidget {
  const UploadFileScreen({super.key});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  File? selectedFile;
  String fileName = "No file selected";

  static const blueGradient = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  static const creamGradient = [
    Color(0xFFFFF3E0),
    Color(0xFFFFE0B2),
  ];

  static const yellowGradient = [
    Color(0xFFFFF59D),
    Color(0xFFFFF176),
  ];

  /// 🔥 PICK FILE
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        fileName = result.files.single.name;
      });
    }
  }

  /// 🔥 PLACEHOLDER (you can connect backend later)
  void processFile() {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a file first")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File processing coming soon")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      /// 🔥 HEADER
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: creamGradient),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              const LinearGradient(colors: blueGradient)
                  .createShader(bounds),
          child: const Text(
            "Upload File",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            /// FILE PREVIEW BOX
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// PICK FILE BUTTON
            _yellowButton(
              text: "Choose File",
              icon: Icons.upload_file,
              onTap: pickFile,
            ),

            const SizedBox(height: 15),

            /// PROCESS BUTTON
            _yellowButton(
              text: "Simplify File",
              icon: Icons.auto_fix_high,
              onTap: processFile,
            ),

            const SizedBox(height: 20),

            /// OUTPUT BOX (STATIC FOR NOW)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: creamGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Simplified text will appear here...",
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),

      /// 🔥 BOTTOM STRIP
      bottomNavigationBar: Container(
        height: 10,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: creamGradient),
        ),
      ),
    );
  }

  /// 🔥 BUTTON (same as reader screen)
  Widget _yellowButton({
    required String text,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: yellowGradient),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.black),
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}