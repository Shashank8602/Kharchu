import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/budgets/budgets_screen.dart';
import 'features/chat/chat_screen.dart';
import 'features/chat/history_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/profile/categories_screen.dart';
import 'features/profile/groq_settings_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/transactions/person_detail_screen.dart';
import 'features/transactions/transactions_screen.dart';
import 'providers.dart';
import 'widgets/pill_nav_bar.dart';
import 'widgets/swipe_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/chat',
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            SwipeShellBody(shell: shell, children: children),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              builder: (_, _) => const ChatScreen(),
              routes: [
                GoRoute(path: 'history', builder: (_, _) => const HistoryScreen()),
              ],
            ),
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
                GoRoute(
                    path: 'categories',
                    builder: (_, _) => const CategoriesScreen()),
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

  @override
  Widget build(BuildContext context) {
    final kc = context.kc;
    final tabs = [
      PillTab(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', kc.soft, kc.softInk),
      PillTab(Icons.pie_chart_outline, Icons.pie_chart, 'Dashboard', kc.lentBg, kc.lentInk),
      PillTab(Icons.receipt_long_outlined, Icons.receipt_long, 'Transactions', kc.warnBg,
          kc.warnInk),
      PillTab(Icons.track_changes_outlined, Icons.track_changes, 'Budgets', kc.borrowedBg,
          kc.borrowedInk),
      PillTab(Icons.person_outline, Icons.person, 'Profile', kc.soft, kc.softInk),
    ];
    return Scaffold(
      body: shell,
      bottomNavigationBar: PillNavBar(
        tabs: tabs,
        selected: shell.currentIndex,
        onSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
