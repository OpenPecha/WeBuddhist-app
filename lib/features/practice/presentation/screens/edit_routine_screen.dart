import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_pecha/features/practice/data/models/routine_model.dart';
import 'package:flutter_pecha/features/practice/data/providers/routine_provider.dart';
import 'package:flutter_pecha/features/practice/data/utils/routine_time_utils.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_plan_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/select_recitation_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_time_block.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class _EditableBlock {
  final String id;
  TimeOfDay time;
  bool notificationEnabled;
  List<RoutineItem> items;

  _EditableBlock({
    String? id,
    required this.time,
    required this.notificationEnabled,
    List<RoutineItem>? items,
  }) : id = id ?? _uuid.v4(),
       items = items ?? [];
}

class EditRoutineScreen extends ConsumerStatefulWidget {
  const EditRoutineScreen({super.key});

  @override
  ConsumerState<EditRoutineScreen> createState() => _EditRoutineScreenState();
}

class _EditRoutineScreenState extends ConsumerState<EditRoutineScreen> {
  late List<_EditableBlock> _blocks;

  @override
  void initState() {
    super.initState();
    final existingData = ref.read(routineProvider);
    if (existingData.hasItems) {
      _blocks =
          existingData.blocks
              .map(
                (b) => _EditableBlock(
                  id: b.id,
                  time: b.time,
                  notificationEnabled: b.notificationEnabled,
                  items: List.from(b.items),
                ),
              )
              .toList();
    } else {
      _blocks = [
        _EditableBlock(
          time: const TimeOfDay(hour: 12, minute: 0),
          notificationEnabled: true,
        ),
      ];
    }
  }

  void _saveAndPop() {
    final blocks =
        _blocks
            .map(
              (b) => RoutineBlock(
                id: b.id,
                time: b.time,
                notificationEnabled: b.notificationEnabled && b.items.isNotEmpty,
                items: b.items,
              ),
            )
            .toList();
    ref.read(routineProvider.notifier).saveRoutine(blocks);
    Navigator.of(context).pop();
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _blocks[index].time,
    );
    if (picked != null) {
      final otherTimes =
          _blocks
              .asMap()
              .entries
              .where((e) => e.key != index)
              .map((e) => e.value.time)
              .toList();
      final adjusted = adjustTimeForMinimumGap(picked, otherTimes);
      setState(() {
        _blocks[index].time = adjusted;
        _sortBlocks();
      });
      if (adjusted != picked && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Adjusted to ${_formatTime(adjusted)} ($kMinBlockGapMinutes-min minimum gap)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _sortBlocks() {
    _blocks.sort(
      (a, b) => (a.time.hour * 60 + a.time.minute).compareTo(
        b.time.hour * 60 + b.time.minute,
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _toggleNotification(int index) {
    setState(() {
      _blocks[index].notificationEnabled = !_blocks[index].notificationEnabled;
    });
  }

  void _deleteBlock(int index) {
    if (_blocks.length > 1) {
      setState(() => _blocks.removeAt(index));
    }
  }

  void _addBlock() {
    final otherTimes = _blocks.map((b) => b.time).toList();
    final defaultTime = const TimeOfDay(hour: 12, minute: 0);
    final adjusted = adjustTimeForMinimumGap(defaultTime, otherTimes);
    setState(() {
      _blocks.add(_EditableBlock(time: adjusted, notificationEnabled: true));
      _sortBlocks();
    });
  }

  void _onReorderItems(int blockIndex, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _blocks[blockIndex].items.removeAt(oldIndex);
      _blocks[blockIndex].items.insert(newIndex, item);
    });
  }

  void _onDeleteItem(int blockIndex, int itemIndex) {
    setState(() {
      _blocks[blockIndex].items.removeAt(itemIndex);
    });
  }

  Future<void> _navigateToSelectPlan(int blockIndex) async {
    final result = await Navigator.of(context).push<PlansModel>(
      MaterialPageRoute(builder: (_) => const SelectPlanScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _blocks[blockIndex].items.add(
          RoutineItem(
            id: result.id,
            title: result.title,
            imageUrl: result.imageThumbnail,
            type: RoutineItemType.plan,
          ),
        );
      });
    }
  }

  Future<void> _navigateToSelectRecitation(int blockIndex) async {
    final result = await Navigator.of(context).push<RecitationModel>(
      MaterialPageRoute(builder: (_) => const SelectRecitationScreen()),
    );
    if (result != null && mounted) {
      setState(() {
        _blocks[blockIndex].items.add(
          RoutineItem(
            id: result.textId,
            title: result.title,
            type: RoutineItemType.recitation,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _DoneButton(
                onTap: _saveAndPop,
                isDark: isDark,
                label: localizations.done,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.routine_edit_title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: _blocks.length + 1, // +1 for add block button
                  separatorBuilder: (_, index) {
                    if (index == _blocks.length - 1) {
                      return const SizedBox(height: 16);
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == _blocks.length) {
                      return _AddBlockButton(onTap: _addBlock, isDark: isDark);
                    }
                    final block = _blocks[index];
                    return RoutineTimeBlock(
                      time: block.time,
                      notificationEnabled: block.notificationEnabled,
                      items: block.items,
                      onTimeChanged: () => _pickTime(index),
                      onNotificationToggle: () => _toggleNotification(index),
                      onDelete: () => _deleteBlock(index),
                      onAddPlan: () => _navigateToSelectPlan(index),
                      onAddRecitation: () => _navigateToSelectRecitation(index),
                      onReorderItems:
                          (oldIdx, newIdx) =>
                              _onReorderItems(index, oldIdx, newIdx),
                      onDeleteItem: (itemIdx) => _onDeleteItem(index, itemIdx),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;
  final String label;

  const _DoneButton({
    required this.onTap,
    required this.isDark,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AddBlockButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDark;

  const _AddBlockButton({required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 16,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Time Block',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
