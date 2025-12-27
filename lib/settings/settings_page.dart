import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/auth/auth_bloc.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.error != current.error && current.error != null,
      listener: (context, state) {
        final message = state.error;
        if (message == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      },
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        final categoriesState = context.watch<CategoryCubit>().state;
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
              // _SettingsSection(
              //   title: 'Currency',
              //   children: [
              //     _SegmentedSetting(
              //       title: 'Base currency',
              //       subtitle: 'Used for dashboards and totals',
              //       child: SegmentedButton<String>(
              //         segments: AppConfig.supportedCurrencies
              //             .map(
              //               (c) => ButtonSegment(
              //                 value: c,
              //                 label: Text(c, style: const TextStyle(fontSize: 12)),
              //               ),
              //             )
              //             .toList(),
              //         selected: {state.baseCurrency},
              //         onSelectionChanged: AppConfig.supportedCurrencies.length == 1
              //             ? null
              //             : (selection) {
              //               context.read<SettingsCubit>().setBaseCurrency(selection.first);
              //             },
              //       ),
              //     ),
              //   ],
              // ),
              _SettingsSection(
                title: 'Categories',
                children: [
                  if (categoriesState.items.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.playlist_add_outlined),
                      title: const Text('Add default categories'),
                      subtitle: const Text('Populate common categories for expenses'),
                      trailing: categoriesState.loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                      onTap: categoriesState.loading ? null : () => context.read<CategoryCubit>().addDefaultCategories(),
                    )
                  else
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Add a custom category'),
                      subtitle: const Text('Add a new label with an optional emoji'),
                      trailing: categoriesState.loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                      onTap: categoriesState.loading ? null : () => _promptAddCategory(context),
                    ),
                ],
              ),
              _SettingsSection(
                title: 'Security',
                children: [
                  SwitchListTile(
                    value: state.appLockEnabled,
                    onChanged: (value) async {
                      final ok = await context.read<SettingsCubit>().setAppLockEnabled(value);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Device authentication unavailable or cancelled.')));
                      }
                    },
                    title: const Text('App lock'),
                    subtitle: const Text('Require device authentication on open and resume'),
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
                    onChanged: (value) => context.read<SettingsCubit>().setTestModeEnabled(value),
                    title: const Text('Test mode'),
                    subtitle: const Text('Show developer tools like test notifications'),
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
                    onTap: () {
                      final theme = Theme.of(context);
                      final repoUrl = Uri.parse('https://github.com/ShubhamGhanmode/Morpheus');
                      showAboutDialog(
                        context: context,
                        applicationName: 'Morpheus',
                        applicationVersion: '1.0.0',
                        children: [
                          const SizedBox(height: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _openRepo(context, repoUrl),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.balance, color: colorScheme.tertiary),
                                        SizedBox(width: 8),
                                        Text(
                                          "MIT License",
                                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.code, color: colorScheme.tertiary),
                                        SizedBox(width: 8),
                                        Text("Repo: ", style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                                      ],
                                    ),

                                    Row(
                                      children: [
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'github.com/ShubhamGhanmode/Morpheus',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.open_in_new, size: 18, color: theme.colorScheme.primary),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Made by Shubham Ghanmode',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      );
                    },
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

  Future<void> _promptAddCategory(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add category'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Category name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emojiCtrl,
                    decoration: const InputDecoration(labelText: 'Emoji (optional)', hintText: 'e.g. 🍔'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldSave && context.mounted) {
      final name = nameCtrl.text.trim();
      final emoji = emojiCtrl.text.trim();
      await context.read<CategoryCubit>().addCategory(name: name, emoji: emoji.isEmpty ? '' : emoji);
    }

    nameCtrl.dispose();
    emojiCtrl.dispose();
  }

  Future<void> _openRepo(BuildContext context, Uri url) async {
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Open settings link failed',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open link')),
      );
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
