import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  final List<Map<String, String>> languages = const [
    {'name': 'English', 'count': '79', 'nativeName': 'English'},
    {'name': 'తెలుగు', 'count': '6', 'nativeName': 'Telugu'},
    {'name': 'हिन्दी', 'count': '7', 'nativeName': 'Hindi'},
    {'name': 'मराठी', 'count': '3', 'nativeName': 'Marathi'},
    {'name': 'தமிழ்', 'count': '2', 'nativeName': 'Tamil'},
    {'name': 'Mizo ṭawng', 'count': '1', 'nativeName': 'Mizo'},
    {'name': 'Khasi', 'count': '1', 'nativeName': 'Khasi'},
    {'name': 'ಕನ್ನಡ', 'count': '1', 'nativeName': 'Kannada'},
    {'name': 'മലയാളം', 'count': '1', 'nativeName': 'Malayalam'},
    {'name': 'বাংলা', 'count': '1', 'nativeName': 'Bangla'},
    {'name': 'Kokborok', 'count': '1', 'nativeName': 'Kokborok'},
    {'name': 'ગુજરાતી', 'count': '1', 'nativeName': 'Gujarati'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50,
        title: const Text('Select a language', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: ListView.separated(
        itemCount: languages.length,
        separatorBuilder:
            (context, index) => const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final language = languages[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Row(
              children: [
                Text(
                  '${language['name']} (${language['count']})',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            trailing: Text(
              language['nativeName']!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            onTap: () {
              // Handle language selection
              Navigator.pop(context, language);
            },
          );
        },
      ),
    );
  }
}
