import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/auth/auth_bloc.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SettingsSection(
                title: 'Account',
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer),
                    ),
                    title: Text(user?.displayName?.trim().isNotEmpty == true ? user!.displayName!.trim() : 'Signed in'),
                    subtitle: Text(user?.email ?? 'No email on file'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Log out'),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _SegmentedSetting(
                    title: 'Theme mode',
                    subtitle: 'Light, dark, or follow system settings',
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.settings_suggest_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.light_mode_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark', style: TextStyle(fontSize: 12)),
                          icon: Icon(Icons.dark_mode_outlined, size: 16),
                        ),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (selection) {
                        context.read<SettingsCubit>().setThemeMode(selection.first);
                      },
                    ),
                  ),
                  _SegmentedSetting(
                    title: 'Contrast',
                    subtitle: 'Increase contrast for better readability',
                    child: SegmentedButton<AppContrast>(
                      segments: [
                        ButtonSegment(
                          value: AppContrast.normal,
                          label: Text(AppContrast.normal.label, style: TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.contrast_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: AppContrast.medium,
                          label: Text(AppContrast.medium.label, style: TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.tonality_outlined, size: 16),
                        ),
                        ButtonSegment(
                          value: AppContrast.high,
                          label: Text(AppContrast.high.label, style: TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.high_quality_outlined, size: 16),
                        ),
                      ],
                      selected: {state.contrast},
                      onSelectionChanged: (selection) {
                        context.read<SettingsCubit>().setContrast(selection.first);
                      },
                    ),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Security',
                children: [
                  SwitchListTile(
                    value: state.appLockEnabled,
                    onChanged: (value) async {
                      final ok = await context
                          .read<SettingsCubit>()
                          .setAppLockEnabled(value);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Device authentication unavailable or cancelled.',
                            ),
                          ),
                        );
                      }
                    },
                    title: const Text('App lock'),
                    subtitle: const Text(
                      'Require device authentication on open and resume',
                    ),
                    secondary: const Icon(Icons.lock_outline_rounded),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Notifications',
                children: [
                  SwitchListTile(
                    value: state.cardRemindersEnabled,
                    onChanged: (value) => context.read<SettingsCubit>().setCardRemindersEnabled(value),
                    title: const Text('Card payment reminders'),
                    subtitle: const Text('Schedule alerts before due dates'),
                    secondary: const Icon(Icons.notifications_active_outlined),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('System notification settings'),
                    subtitle: const Text('Manage permissions from the OS'),
                    onTap: openAppSettings,
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Testing',
                children: [
                  SwitchListTile(
                    value: state.testModeEnabled,
                    onChanged: (value) => context
                        .read<SettingsCubit>()
                        .setTestModeEnabled(value),
                    title: const Text('Test mode'),
                    subtitle: const Text(
                      'Show developer tools like test notifications',
                    ),
                    secondary: const Icon(Icons.science_outlined),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Support',
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Morpheus'),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Morpheus',
                      applicationLegalese: 'Smart finance companion',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Log out'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Log out'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && context.mounted) {
      context.read<AuthBloc>().add(const SignOutRequested());
    }
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tiles = ListTile.divideTiles(context: context, tiles: children).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Column(children: tiles),
          ),
        ],
      ),
    );
  }
}

class _SegmentedSetting extends StatelessWidget {
  const _SegmentedSetting({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: child),
        ],
      ),
    );
  }
}
