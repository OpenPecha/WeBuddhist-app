import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:go_router/go_router.dart';

/// Opens a chant/recitation in the shared reader with practice-context actions
/// (e.g. "Add to my practices" in the more menu).
void openRecitationReader(BuildContext context, RecitationModel recitation) {
  context.push(
    '/reader/${recitation.textId}',
    extra: const NavigationContext(source: NavigationSource.recitationList),
  );
}
