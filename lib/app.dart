import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/groq_settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/transactions/person_detail_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/chat',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/chat', builder: (_, _) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (_, _) => const TransactionsScreen(),
              routes: [
                GoRoute(
                  path: 'person/:id',
                  builder: (_, state) => PersonDetailScreen(
                    // a bad id shows "Not found" instead of crashing
                    personId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/budgets', builder: (_, _) => const BudgetsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (_, _) => const ProfileScreen(),
              routes: [
                GoRoute(
                    path: 'groq',
                    builder: (_, _) => const GroqSettingsScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class KharchuApp extends ConsumerWidget {
  const KharchuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Kharchu',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
    (Icons.pie_chart_outline, Icons.pie_chart, 'Dashboard'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions'),
    (Icons.track_changes_outlined, Icons.track_changes, 'Budgets'),
    (Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: kc.line))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(t.$1),
                selectedIcon: Icon(t.$2),
                label: t.$3,
              ),
          ],
        ),
      ),
    );
  }
}
