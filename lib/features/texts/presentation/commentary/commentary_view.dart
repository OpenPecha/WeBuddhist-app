import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Dummy data model
class Commentary {
  final String segmentId;
  final String textId;
  final String title;
  final String content;
  final String language;
  final int count;

  Commentary({
    required this.segmentId,
    required this.textId,
    required this.title,
    required this.content,
    required this.language,
    required this.count,
  });
}

// Dummy data list
final dummyCommentaries = List.generate(
  4,
  (i) => Commentary(
    segmentId: "5348b2bb-aa75-4157-b5e0-ff45ae74f721",
    textId: "a48c0814-ce56-4ada-af31-f74b179b52a9",
    title: "ཤེས་རབ་འབྱུང་གནས། སྤྱོད་འཇུག་དཀའ་འགྲེལ།",
    content:
        """རང་དང་གཞན་ལ་ཕན་པའི་རྒྱུ་ཉིད་ཡིན་པ་འདིའི་ཕྱིར་ཡང་བྱང་ཆུབ་ཀྱི་སེམས་ཡོངས་སུ་གཏོང་བར་མི་བྱའོ་ཞེས་བསྟན་པའི་ཕྱིར། སྲིད་པའི་སྡུག་བསྔལ་ཞེས་བྱ་བ་ལ་སོགས་པ་གསུངས་ཏེ། འཁོར་བར་གནས་པའི་དམྱལ་བ་ལ་སོགས་པའི་འགྲོ་བའི་སྡུག་བསྔལ་བདེ་བ་མ་ཡིན་པ་མྱོང་བ་རྣམས་ཡིན་ལ། བརྒྱ་ཕྲག་ནི་མཐར་ཐུག་པ་མེད་པའི་ཚོགས་སོ།།
གཞོམ་འདོད་པ་ནི་ཡོངས་སུ་འདོར་བར་འདོད་པས་དེ་ཉན་ཐོས་དང་རང་སངས་རྒྱས་ཀྱི་རིགས་རྣམས་ཀྱིས་སོ།།
བདག་ཉིད་འབའ་ཞིག་གི་མ་ཡིན་པར་འཇིག་རྟེན་པ་རྣམས་ཀྱི་སྐྱེ་བ་ལ་སོགས་པའི་སྡུག་བསྔལ་ཡང་བསལ་བར་འདོད་པ་ནི་བྲལ་བར་འདོད་པ་སྟེ། བྱང་ཆུབ་སེམས་དཔའི་རིགས་རྣམས་ཀྱིས་སོ།།
གཅིག་ཏུ་རང་དང་གཞན་གྱི་སྡུག་བསྔལ་བསལ་བར་འདོད་པ་མ་ཡིན་གྱི། གཞན་ཡང་བདེ་བ་དང་སྐྱིད་པ་མང་པོ་སྟེ། དེ་རྣམས་ཀྱི་བརྒྱ་ཕྲག་ནི་ལྷ་དང་མི་རྣམས་ཀྱི་སྐྱེ་བ་འཐོབ་པ་ཉམས་སུ་མྱོང་བར་འདོད་པ་སྟེ། འཁོར་བའི་བདེ་བ་འདོད་པས་ཀྱང་ངོ་།།
རྟག་ཏུ་ནི་དུས་ཐམས་ཅད་དུའོ།།
གཏང་མི་བྱ་བ་སྟེ། བྱང་ཆུབ་ཀྱི་སེམས་ཁས་བླང་བར་བྱའོ་ཞེས་བྱ་བའི་དོན་ཏོ།།""",
    language: "bo",
    count: 1,
  ),
);

// State provider for expanded index
final expandedCommentaryProvider = StateProvider<int?>((ref) => null);

class CommentaryView extends ConsumerWidget {
  const CommentaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expandedIndex = ref.watch(expandedCommentaryProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dummyCommentaries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'All Commentary (${dummyCommentaries.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          final commentary = dummyCommentaries[index - 1];
          final isExpanded = expandedIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 16, top: 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commentary.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 2,
                  color: const Color(0xFFB6D7D7),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Text(
                  isExpanded
                      ? commentary.content
                      : _getPreview(commentary.content),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!isExpanded)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed:
                          () =>
                              ref
                                  .read(expandedCommentaryProvider.notifier)
                                  .state = index,
                      child: Text(
                        'Read more',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                if (isExpanded)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            () =>
                                ref
                                    .read(expandedCommentaryProvider.notifier)
                                    .state = null,
                        child: Text(
                          'Show less',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPreview(String content) {
    const maxLen = 150;
    if (content.length <= maxLen) return content;
    return content.substring(0, maxLen);
  }
}
