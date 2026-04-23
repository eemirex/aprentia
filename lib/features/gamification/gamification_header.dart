import 'package:flutter/material.dart';
import '../shell/app_shell.dart';

class GamificationHeader extends StatelessWidget {
  const GamificationHeader({super.key});

  int _levelFromXp(int xp) => (xp ~/ 100) + 1;
  double _xpProgress(int xp) => (xp % 100) / 100;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final level = _levelFromXp(state.xp);
    final progress = _xpProgress(state.xp);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C63FF),
            Color(0xFF8F88FF),
          ],
        ),
      ),
      child: Row(
        children: [
          // LEVEL CIRCLE
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                'Lv $level',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // XP + STREAK
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${state.streak} day streak',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),

                const SizedBox(height: 4),
                Text(
                  '${state.xp % 100}/100 XP to next level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
