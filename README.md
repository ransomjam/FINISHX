# FinishX — One Journey. Full Focus.

FinishX is a commitment and accountability Flutter application designed to help people consistently honour their learning and personal commitments and finish what they start.

## Brand & Design System

- **Palette (Forest & Kinetic Mint):** Forest Ink (`#153B35`), Deep Spruce (`#285B50`), Kinetic Mint (`#72E3B6`), Warm Chalk (`#F4F2E9`), Pure Surface (`#FFFFFF`), Soft Sage (`#DCE6DE`), Carbon (`#202A27`), Muted Brick (`#B96C61`).
- **Typography:** Bundled local variable TrueType fonts (`Manrope` for display/headings and `Inter` for body/labels/forms) for 100% offline fidelity.
- **Logo:** Custom vector-drawn `FX` mark depicting two intersecting paths converging toward a shared Kinetic Mint completion endpoint.

## Architecture

Organised into clean feature and domain layers under `lib/`:
- `core/` — Design tokens, Material 3 theme customisation, custom FX logo painter, reusable cards/buttons/progress rings, sync indicators, and timezone-aware date/time utilities.
- `domain/` — Typed entities, enums, `CommitmentCalculator`, `JourneyRulesService` (enforcing *One Journey. Full Focus.*), and `ProgressMetricsService` (keeping authoritative journey-progress and group-health formulas isolated from UI).
- `data/` — `SharedPreferences`-backed local persistence (`LocalStorageDataSource`), honest offline/pending sync queue (`SyncRepository` + `UnconfiguredRemoteSyncDataSource`), and isolated demo seed data (`DemoSeedDataSource`).
- `application/` — Modular Riverpod state controllers and `GoRouter` navigation shell with custom 4-item bottom navigation (`Home`, `Journey`, `Group`, `Archive`).
- `features/` — All 18 screens across Auth, 7-step Onboarding Wizard, Group Welcome, Home Dashboard, My Journey, Schedule, Focus Mode, Session Reflection, Journey Update, Accountability Group & Feed, Weekly Check-In, Completion Reflection & Celebration, Journey Archive, and Journey Queue.

## Running & Testing

```bash
flutter run
dart format .
flutter analyze
flutter test
```
