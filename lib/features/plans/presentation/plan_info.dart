import 'package:fpdart/fpdart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/error/failures.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/plans/domain/entities/plan.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/data/utils/plan_utils.dart';
import 'package:flutter_pecha/features/plans/data/models/response/user_plan_list_response_model.dart';
import 'package:flutter_pecha/features/plans/data/models/user/user_plans_model.dart';
import 'package:flutter_pecha/features/plans/presentation/author_detail_screen.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerStatefulWidget {
  const PlanInfo({super.key, required this.plan, this.author});
  final Plan plan;
  final String? author;
  @override
  ConsumerState<PlanInfo> createState() => _PlanInfoState();
}

class _PlanInfoState extends ConsumerState<PlanInfo> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isGuest = authState.isGuest;
    final isLoggedIn = authState.isLoggedIn;

    // Get enrolled plan IDs
    List<String> enrolledPlanIds = [];
    if (!isGuest && isLoggedIn) {
      final subscribedPlans = ref.watch(userPlansFutureProvider);
      enrolledPlanIds = subscribedPlans.valueOrNull?.fold(
        (failure) => <String>[],
        (response) => response.userPlans.map((e) => e.id).toList(),
      ) ?? <String>[];
    }

    final language = widget.plan.language.toLowerCase();
    final localizations = context.l10n;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        title: Text(localizations.plan_info, style: TextStyle(fontSize: 20)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanImage(context),
              _buildPlanTitleDays(context, language),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildPlanDescription(context),
              ),
              const SizedBox(height: 16),
              _buildAuthorAvatar(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildActionButtons(
                  context,
                  enrolledPlanIds,
                  isGuest,
                  language,
                  localizations,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return CachedNetworkImageWidget(
      imageUrl: widget.plan.coverImageUrl ?? '',
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.25,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildPlanTitleDays(BuildContext context, String language) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: context.languageTitleStyle(language),
                ),
                SizedBox(height: 4),
                Text(
                  '${widget.plan.totalDays} Days',
                  style: context.languageTextStyle(
                    language,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          _buildAuthorAvatar(context),
        ],
      ),
    );
  }

  Widget _buildPlanDescription(BuildContext context) {
    return Text(
      widget.plan.description,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildAuthorAvatar(BuildContext context) {
    final authorId = widget.plan.authorId;
    final authorName = widget.author;

    // Handle null author case
    if (authorId.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AuthorDetailScreen(authorId: authorId),
          ),
        );
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<String> enrolledPlanIds,
    bool isGuest,
    String language,
    AppLocalizations localizations,
  ) {
    final isSubscribed = enrolledPlanIds.contains(widget.plan.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags
        if (widget.plan.tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.plan.tags.take(3).map((tag) {
              return Chip(
                label: Text(tag),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        // Enroll/Start button
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              if (isSubscribed) {
                // Navigate to practice
                context.push('/practice');
              } else {
                // Handle enrollment
                _handleEnroll(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: isSubscribed ? Colors.grey : Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isSubscribed
                  ? 'Go to Practice'
                  : 'Enroll',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEnroll(BuildContext context) async {
    // TODO: Implement enrollment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Enrollment coming soon!')),
    );
  }
}
