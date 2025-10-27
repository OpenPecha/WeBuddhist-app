import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/author/author_dto_model.dart';
import 'package:flutter_pecha/features/plans/data/providers/author_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AuthorDetailScreen extends ConsumerWidget {
  final AuthorDtoModel author;

  const AuthorDetailScreen({super.key, required this.author});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch full author details using the author ID
    final authorDetails = ref.watch(authorByIdFutureProvider(author.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Author'), elevation: 0),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: authorDetails.when(
        data: (authorData) => _buildAuthorContent(context, authorData),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load author details',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(authorByIdFutureProvider(author.id));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildAuthorContent(BuildContext context, authorData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, authorData),
          _buildBioSection(context, authorData),
          _buildSocialMediaSection(context, authorData),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, authorData) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  authorData.avatarUrl != null &&
                          authorData.avatarUrl!.isNotEmpty
                      ? NetworkImage(authorData.avatarUrl!)
                      : null,
              backgroundColor: Colors.grey[800],
              child:
                  authorData.avatarUrl == null || authorData.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        authorData.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (authorData.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          authorData.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection(BuildContext context, authorData) {
    if (authorData.bio == null || authorData.bio!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
      child: Text(
        authorData.bio!,
        style: const TextStyle(fontSize: 15, height: 1.7),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildSocialMediaSection(BuildContext context, authorData) {
    if (authorData.socialProfiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Social Media',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...authorData.socialProfiles.map(
            (profile) => _buildSocialMediaItem(context, profile),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaItem(BuildContext context, socialProfile) {
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
          Expanded(
            child: Text(
              '${socialProfile.platform}: ${socialProfile.url}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
