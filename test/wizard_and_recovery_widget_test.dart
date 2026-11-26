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
    '7-step Journey Creation Wizard creates journey and opens Group Welcome',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fixedNow = DateTime(2026, 11, 25, 10, 0);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => fixedNow),
        ],
      );
      addTearDown(container.dispose);

      // Sign in user with no existing journey -> routes to Wizard after Splash
      await container
          .read(authControllerProvider.notifier)
          .signIn(
            provider: AuthProviderType.email,
            displayName: 'Morgan Vance',
            email: 'morgan@example.com',
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinishXApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      // Step 1: Journey Name
      expect(find.text('What journey are you starting?'), findsOneWidget);
      await tester.tap(find.text('Learn Python'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Category
      expect(find.text('Choose a journey category'), findsOneWidget);
      await tester.tap(find.text('Software Engineering'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Learning Resource
      expect(
        find.text('What resource will you use for this journey?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Timeline
      expect(find.text('Set your journey timeline'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 5: Commitment Days (defaults preselected Mon/Wed/Sat)
      expect(find.text('Choose your commitment days'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 6: Schedule
      expect(find.text('Set your commitment schedule'), findsOneWidget);
      expect(find.text('WEEKLY SESSIONS'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 7: Commitment Confirmation & Sign Commitment
      expect(find.text('Review & sign your commitment'), findsOneWidget);
      expect(find.text('Sign Commitment'), findsOneWidget);
      await tester.tap(find.text('Sign Commitment'));
      await tester.pumpAndSettle();

      // Lands on Group Welcome Screen
      expect(find.textContaining('Software Engineering Group'), findsWidgets);
      expect(find.text('Continue to Dashboard'), findsOneWidget);
      await tester.tap(find.text('Continue to Dashboard'));
      await tester.pumpAndSettle();

      // Dashboard shows signed journey
      expect(find.text('Learn Python'), findsOneWidget);
    },
  );

  testWidgets(
    'Missed session displays supportive recovery message on Dashboard',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final wednesdayMorning = DateTime(2026, 11, 25, 8, 0);
      var currentNow = wednesdayMorning;

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          clockProvider.overrideWithValue(() => currentNow),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signIn(
            provider: AuthProviderType.email,
            displayName: 'Samira Ali',
            email: 'samira@example.com',
          );
      await container
          .read(journeyWorkspaceProvider.notifier)
          .createAndSignJourney(
            name: 'Write a Book',
            category: JourneyCategory.personalDevelopment,
            resource: const LearningResource(
              type: ResourceType.personalStudyPlan,
            ),
            startDate: wednesdayMorning,
            targetCompletionDate: wednesdayMorning.add(
              const Duration(days: 60),
            ),
            commitmentDays: const [
              CommitmentDay(
                weekday: DateTime.wednesday,
                startHour: 9,
                startMinute: 0,
                endHour: 10,
                endMinute: 0,
              ),
              CommitmentDay(
                weekday: DateTime.friday,
                startHour: 9,
                startMinute: 0,
                endHour: 10,
                endMinute: 0,
              ),
            ],
          );

      // Advance time past Wednesday's 9-10am session so it becomes Missed
      currentNow = DateTime(2026, 11, 26, 9, 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FinishXApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "One missed session doesn't define your journey. The next commitment is what matters.",
        ),
        findsOneWidget,
      );
      expect(find.text('Resume My Journey'), findsOneWidget);

      await tester.tap(find.byType(Scrollable).first, warnIfMissed: false);
      await tester.tap(find.text('Resume My Journey'));
      await tester.pumpAndSettle();

      expect(find.text('Resume My Journey'), findsNothing);
    },
  );
}
