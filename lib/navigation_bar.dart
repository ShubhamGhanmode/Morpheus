import 'package:flutter/material.dart';
import 'package:morpheus/accounts.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/expenses/view/expense_dashboard_page.dart';
import 'package:morpheus/settings/settings_page.dart';

/// Root shell that holds a Material 3 bottom NavigationBar and preserves
/// each tab's state via an IndexedStack.
///
/// Add this as your home in MaterialApp (with useMaterial3: true).
class AppNavShell extends StatefulWidget {
  const AppNavShell({super.key});

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  int _index = 0;

  // Keep tab widgets alive to preserve state/animations when switching.
  final _tabs = [
    ExpenseDashboardPage(),
    CreditCardManagementPage(),
    AccountsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body holds the active tab; IndexedStack preserves offstage children.
      body: IndexedStack(index: _index, children: _tabs),

      // Material 3 bottom nav
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.credit_card_outlined),
            selectedIcon: Icon(Icons.credit_card),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
