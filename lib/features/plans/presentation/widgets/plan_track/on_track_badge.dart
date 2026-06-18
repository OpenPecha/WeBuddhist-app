import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

/// Outlined "On Track!" pill shown next to a plan the user is enrolled in
/// when today falls within the plan's date range AND no scheduled days have
/// been missed. Visually mirrors `MissedDaysBadge` for consistency.
class OnTrackBadge extends StatelessWidget {
  const OnTrackBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Text(
        context.l10n.plan_status_on_track,
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }
}
