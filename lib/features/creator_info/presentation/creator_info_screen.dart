import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatorInfoScreen extends ConsumerWidget {
  const CreatorInfoScreen({super.key});

  static const List<String> _planItems = ["Medicine Buddha Healing"];

  static const credits = [
    {
      "language": "bo",
      "name": "ཡེ་ཤེས་ལྷུན་གྲུབ།",
      "bio":
          "ཡེ་ཤེས་ལྷུན་གྲུབ་ནི་ནང་པ་ཞིག་ཡིན་པ་དང་། ཁོང་གིས་དབྱིན་ཡིག་ཐོག་ཏུ་བརྩེ་བ་དང་ཤེས་རབ་གཉིས་བསྡོམས་ན་བདེ་བ་ཡིན་ཞེས་པའི་དེབ་ཅིག་བྲིས་ཡོད།",
    },
    {
      "language": "zh",
      "name": "耶喜嘉措（Jay）",
      "bio": "希望能把佛法的內容以現代化的方式，傳達給所有對佛法有興趣的人。",
    },
    {"language": "en", "name": "Kevin", "bio": "大家好，我是Kevin, 來自台灣。"},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final currentLanguage = language?.languageCode ?? 'en';
    final currentCredits = credits.firstWhere(
      (credit) => credit['language'] == currentLanguage,
      orElse: () => credits.firstWhere((credit) => credit['language'] == 'en'),
    );
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, currentCredits),
            _buildBioSection(context, currentCredits),
            _buildFeaturedPlanSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> currentCredits,
  ) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Done',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: const AssetImage(
                    'assets/images/pecha_logo.png',
                  ),
                  backgroundColor: Colors.grey[800],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentCredits['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(
    BuildContext context,
    Map<String, dynamic> currentCredits,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentCredits['bio'],
            style: TextStyle(fontSize: 15, height: 1.7),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPlanSection(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Featured Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ..._planItems.map((item) => _buildPlanItem(context, item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.foregroundColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
