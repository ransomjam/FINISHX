import 'package:finishx/app.dart';
import 'package:finishx/application/providers/app_providers.dart';
import 'package:finishx/domain/enums/app_enums.dart';
import 'package:finishx/domain/models/commitment_day.dart';
import 'package:finishx/domain/models/learning_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'Unauthenticated user sees Splash then Welcome screen with brand copy',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const FinishXApp(),
        ),
      );

      // Advance past 900ms splash delay and animations
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.text('You have something to finish.'), findsOneWidget);
      expect(find.text('Start Your Journey'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    },
  );

  testWidgets(
    'Authenticated user navigates Home, Focus Mode, Reflection, Update, and Bottom Tabs',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fixedNow = DateTime(2026, 11, 25, 9, 30);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Sign in & create active journey via controllers
      await container
          .read(authControllerProvider.notifier)
          .signIn(
            provider: AuthProviderType.email,
            displayName: 'Taylor Brooks',
            email: 'taylor@example.com',
          );
      await container
          .read(journeyWorkspaceProvider.notifier)
          .createAndSignJourney(
            name: 'Become a Data Scientist',
            category: JourneyCategory.dataScience,
            resource: const LearningResource(
              type: ResourceType.coursera,
              name: 'ML Track',
            ),
            startDate: fixedNow,
            targetCompletionDate: fixedNow.add(const Duration(days: 60)),
            commitmentDays: const [
              CommitmentDay(
                weekday: DateTime.wednesday,
                startHour: 19,
                startMinute: 0,
                endHour: 20,
                endMinute: 0,
              ),
            ],
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinishXApp(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      // Verify Dashboard renders user name, active journey, and prominent Start Session CTA
      expect(find.text('Taylor Brooks'), findsOneWidget);
      expect(find.text('Become a Data Scientist'), findsOneWidget);
      expect(find.text('Start Session'), findsOneWidget);

      // Navigate across the 4 bottom navigation tabs: Home, Journey, Group, Archive
      await tester.tap(find.text('Journey'));
      await tester.pumpAndSettle();
      expect(find.text('My Journey'), findsOneWidget);

      await tester.tap(find.text('Group'));
      await tester.pumpAndSettle();
      expect(find.text('Accountability Group'), findsOneWidget);

      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(find.text('Journey Archive'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Start Session -> Focus Mode (no timer, minimal commitment screen)
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      expect(find.text('Your commitment starts now.'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);

      // End Session -> Session Reflection
      await tester.tap(find.text('End Session'));
      await tester.pumpAndSettle();

      expect(find.text("How did today's session feel?"), findsOneWidget);
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      // Optional Journey Update screen -> Skip back to Dashboard
      expect(find.text('What progress did you make today?'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Taylor Brooks'), findsOneWidget);
    },
  );
}
