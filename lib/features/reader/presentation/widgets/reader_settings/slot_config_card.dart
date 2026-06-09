import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/reader/data/models/reader_slot_config.dart';

/// When [enabled] is false, the whole card dims and rows are
/// not tappable — used to disable the secondary card when the toggle is off.
class SlotConfigCard extends StatelessWidget {
  const SlotConfigCard({
    super.key,
    required this.headerLabel,
    required this.config,
    required this.onLanguage,
    required this.onVersion,
    required this.onScript,
    this.enabled = true,
    this.showScriptRow = true,
  });

  final String headerLabel;
  final ReaderSlotConfig config;
  final VoidCallback onLanguage;
  final VoidCallback onVersion;
  final VoidCallback onScript;
  final bool enabled;
  final bool showScriptRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Text(
              headerLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.3,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              children: [
                _SlotRow(
                  label: l10n.language,
                  value: config.languageLabel,
                  enabled: enabled,
                  onTap: onLanguage,
                ),
                _rowDivider(theme),
                _SlotRow(
                  label: l10n.version,
                  value: config.versionLabel ?? '—',
                  enabled: enabled,
                  onTap: onVersion,
                ),
                // Script row hidden for now — keep callback wiring intact.
                // if (showScriptRow) ...[
                //   _rowDivider(theme),
                //   _SlotRow(
                //     label: 'Script',
                //     value: config.scriptLabel ?? 'Roman',
                //     enabled: enabled,
                //     onTap: onScript,
                //   ),
                // ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider(ThemeData theme) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: theme.dividerColor.withValues(alpha: 0.35),
  );
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
