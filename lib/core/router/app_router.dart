import 'package:dose_time/core/widgets/scaffold_with_navbar.dart';
import 'package:dose_time/features/medication/presentation/screens/add_medication_screen.dart';
import 'package:dose_time/features/medication/presentation/screens/edit_medication_screen.dart';
import 'package:dose_time/features/medication/presentation/screens/medication_list_screen.dart';
import 'package:dose_time/features/medication/presentation/screens/home_screen.dart';
import 'package:dose_time/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/disclaimer_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/pro_upgrade_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/settings_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/data_management_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/contacts_screen.dart';
import 'package:dose_time/features/settings/presentation/screens/add_edit_contact_screen.dart';
import 'package:dose_time/features/history/presentation/screens/history_screen.dart';
import 'package:dose_time/features/history/presentation/screens/adherence_insights_screen.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      if (!settings.onboardingComplete && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      if (!settings.disclaimerAccepted && state.matchedLocation != '/disclaimer' && state.matchedLocation != '/onboarding') {
        return '/disclaimer';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavbar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medications',
                builder: (context, state) => const MedicationListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: _rootNavigatorKey, 
                    builder: (context, state) => const AddMedicationScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => EditMedicationScreen(
                      medicationId: int.parse(state.pathParameters['id']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: 'insights',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AdherenceInsightsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'contacts',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ContactsScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const AddEditContactScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => AddEditContactScreen(
                          contactId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'data',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const DataManagementScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/upgrade',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProUpgradeScreen(),
      ),
    ],
  );
});
