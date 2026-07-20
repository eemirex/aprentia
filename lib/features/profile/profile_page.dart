import 'package:flutter/material.dart';
import '../shell/app_shell.dart';
import '../auth/auth_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _name = TextEditingController();
  final _goal = TextEditingController();

  String _skill = 'Beginner';
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppScope.of(context);

    // Populate once (avoid overwriting user typing)
    if (_name.text.isEmpty) _name.text = state.displayName;
    if (_goal.text.isEmpty) _goal.text = state.goal;
    _skill = state.skillLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = AppScope.of(context);
    setState(() => _saving = true);

    try {
      await state.updateProfile(
        newDisplayName: _name.text,
        newGoal: _goal.text,
        newSkillLevel: _skill,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmReset() async {
    final state = AppScope.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This clears XP, streak, hearts, completed lessons, badges, and practice history on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await state.resetAll();
    if (!mounted) return;

    _name.text = state.displayName;
    _goal.text = state.goal;
    setState(() => _skill = state.skillLevel);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset complete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _StatsCard(
            xp: state.xp,
            streak: state.streak,
            hearts: state.hearts,
            level: state.level,
          ),
          const SizedBox(height: 14),

          _SectionTitle('Your profile'),
          const SizedBox(height: 8),

          _InputCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _goal,
                  textInputAction: TextInputAction.newline,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Goal',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _skill,
                  decoration: const InputDecoration(
                    labelText: 'Skill level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                    DropdownMenuItem(value: 'Intermediate', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                  ],
                  onChanged: (v) => setState(() => _skill = v ?? 'Beginner'),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionTitle('Account'),
          const SizedBox(height: 8),

          _InputCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowLine(
                  label: 'Status',
                  value: state.isAnonymous ? 'Guest (anonymous)' : 'Signed in',
                ),
                const SizedBox(height: 6),
                _RowLine(
                  label: 'Email',
                  value: state.email.isEmpty ? '-' : state.email,
                ),
                const SizedBox(height: 12),

                if (state.emailOtpSupported) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthPage()),
                        );
                      },
                      child: Text(state.isAnonymous ? 'Upgrade with email' : 'Manage account'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!state.isAnonymous)
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () async {
                          await state.signOut();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Signed out')),
                          );
                        },
                        child: const Text('Sign out'),
                      ),
                    ),
                ] else
                  Text(
                    'Email upgrade is available once Supabase is configured.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _SectionTitle('Danger zone'),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _confirmReset,
              child: const Text('Reset local progress'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int xp;
  final int streak;
  final int hearts;
  final String level;

  const _StatsCard({
    required this.xp,
    required this.streak,
    required this.hearts,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _Pill(label: 'Level', value: level),
          _Pill(label: 'XP', value: '$xp'),
          _Pill(label: 'Streak', value: '$streak'),
          _Pill(label: 'Hearts', value: '$hearts'),
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

class _InputCard extends StatelessWidget {
  final Widget child;
  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
    );
  }
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;
  const _RowLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
