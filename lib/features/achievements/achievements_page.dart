import 'package:flutter/material.dart';
import '../shell/app_shell.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  bool _checkedPopup = false;

  // Define your badges here (id must match AppState unlock ids)
  static const _badges = <_BadgeDef>[
    _BadgeDef(
      id: 'first_steps',
      title: 'First Steps',
      subtitle: 'Earn 50 XP',
      icon: Icons.rocket_launch,
      description:
          'You earned your first meaningful progress. Keep going and stack small wins.',
    ),
    _BadgeDef(
      id: 'streak_3',
      title: '3-Day Streak',
      subtitle: 'Active 3 days in a row',
      icon: Icons.local_fire_department,
      description:
          'Consistency builds skill. Short sessions beat long sessions done rarely.',
    ),
    _BadgeDef(
      id: 'streak_7',
      title: '7-Day Streak',
      subtitle: 'Active 7 days in a row',
      icon: Icons.whatshot,
      description:
          'A full week of momentum. You are building a real learning habit.',
    ),
    _BadgeDef(
      id: 'course_3',
      title: 'Course Explorer',
      subtitle: 'Complete 3 course lessons',
      icon: Icons.menu_book,
      description:
          'You invested in fundamentals. Structure unlocks speed and quality.',
    ),
    _BadgeDef(
      id: 'course_10',
      title: 'Course Finisher',
      subtitle: 'Complete 10 course lessons',
      icon: Icons.school,
      description:
          'You completed serious learning mileage. You are ready for advanced prompts.',
    ),
    _BadgeDef(
      id: 'practice_5',
      title: 'Practice Starter',
      subtitle: 'Finish 5 practice sessions',
      icon: Icons.bolt,
      description:
          'Practice is where learning becomes ability. Keep grading and improving.',
    ),
    _BadgeDef(
      id: 'practice_20',
      title: 'Practice Pro',
      subtitle: 'Finish 20 practice sessions',
      icon: Icons.workspace_premium,
      description:
          'You put in the reps. Your prompting instincts are getting strong.',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show unlock animation once after the page is in the tree
    if (_checkedPopup) return;
    _checkedPopup = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = AppScope.of(context);
      final unlockedId = state.consumeLastUnlockedBadgeId();
      if (unlockedId == null || unlockedId.isEmpty) return;

      final def = _badges.firstWhere(
        (b) => b.id == unlockedId,
        orElse: () => const _BadgeDef(
          id: 'unknown',
          title: 'Badge Unlocked',
          subtitle: '',
          icon: Icons.emoji_events,
          description: '',
        ),
      );

      _showUnlockedModal(def);
    });
  }

  void _showBadgeDetail(_BadgeDef def, bool unlocked) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgeHeader(def: def, unlocked: unlocked),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  def.description.isEmpty
                      ? 'No description yet.'
                      : def.description,
                  style: const TextStyle(height: 1.35, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Row(
                        children: [
                          Icon(unlocked ? Icons.check_circle : Icons.lock),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              unlocked ? 'Unlocked' : 'Locked',
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showUnlockedModal(_BadgeDef def) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _UnlockedDialog(def: def),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final unlockedCount =
        _badges.where((b) => state.isBadgeUnlocked(b.id)).length;
    final total = _badges.length;
    final progress = total == 0 ? 0.0 : unlockedCount / total; // double

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _TopSummaryCard(
            unlockedCount: unlockedCount,
            total: total,
            progress: progress,
            xp: state.xp,
            streak: state.streak,
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _badges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemBuilder: (context, i) {
              final def = _badges[i];
              final unlocked = state.isBadgeUnlocked(def.id);

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _showBadgeDetail(def, unlocked),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    color: unlocked
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Icon(
                              def.icon,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          Icon(unlocked ? Icons.check_circle : Icons.lock),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        def.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        def.subtitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        unlocked ? 'Unlocked' : 'Tap for details',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopSummaryCard extends StatelessWidget {
  final int unlockedCount;
  final int total;
  final double progress;
  final int xp;
  final int streak;

  const _TopSummaryCard({
    required this.unlockedCount,
    required this.total,
    required this.progress,
    required this.xp,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your progress',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress, // double ok
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$unlockedCount / $total badges - $pct%',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Pill(label: 'XP', value: '$xp'),
              _Pill(label: 'Streak', value: '$streak'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final String value;
  const _Pill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _UnlockedDialog extends StatefulWidget {
  final _BadgeDef def;
  const _UnlockedDialog({required this.def});

  @override
  State<_UnlockedDialog> createState() => _UnlockedDialogState();
}

class _UnlockedDialogState extends State<_UnlockedDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  late final Animation<double> _scale =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Badge Unlocked!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              _BadgeHeader(def: widget.def, unlocked: true),
              const SizedBox(height: 12),
              Text(
                widget.def.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nice'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeHeader extends StatelessWidget {
  final _BadgeDef def;
  final bool unlocked;

  const _BadgeHeader({
    required this.def,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Icon(def.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(def.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  unlocked ? 'Unlocked' : 'Locked',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Icon(unlocked ? Icons.check_circle : Icons.lock),
        ],
      ),
    );
  }
}

class _BadgeDef {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String description;

  const _BadgeDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.description,
  });
}
