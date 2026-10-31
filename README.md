# Habit Mastery App

**Team:** Anti-Procrastinators — Jamal Lyons and Areeb Ur Rahman

**Course:** CSC4360 Mobile Application Development, Georgia State University

**Pathway:** Undergraduate

**Repository:** [P1_habit_mastery_app](https://github.com/arahman-25/P1_habit_mastery_app)

Habit Mastery is an offline-first Flutter habit tracker built around weekly goals and correctable check-in history. Its garden is a visual summary of progress; missed days do not reset a streak because the app does not use streaks.

## App overview

The app has five user-facing screen roles:

1. **Dashboard:** habit catalog, category filter, this-week progress, and quick check-in.
2. **Create/edit habit:** validated title, category, weekly target, start date, and motivation.
3. **Detail/activity:** weekly progress, check-in action, cycle status, and resettable view state.
4. **History/insights:** add, view, edit, and delete check-ins; browse weeks; view the Garden Guide.
5. **Settings:** local preferences, default weekly target, database status, and data reset.

Habit and check-in records are stored in SQLite on the device. The Garden Guide is a deterministic, rule-based estimate calculated from the last three eligible completed weeks. It explains its suggestion and only applies it after the user taps **Apply Suggestion**. See [AI_FEATURE.md](AI_FEATURE.md) for the method and fixture details.

## Requirements and boundaries

- App records and settings are local. The app has no account, remote sync, cloud database, or cloud inference.
- A habit has a weekly target from 1 to 7 days.
- A habit can have at most one check-in for a local calendar date.
- Check-ins cannot be before the habit start date or after today.
- Deleting a habit requires confirmation and SQLite cascades its check-ins.
- Weekly dates are represented as local `YYYY-MM-DD` strings. Weeks run Monday through Sunday.
- Weekly counts and plant tiers are derived from check-in rows; they are not stored separately.

## Run locally

Prerequisites: Flutter and Dart versions compatible with the constraints in `habit_mastery_app/pubspec.yaml`, plus Android Studio/Xcode tooling for the target platform.

```sh
cd habit_mastery_app
flutter pub get
flutter run
```

To run the automated suite and static analysis:

```sh
cd habit_mastery_app
flutter test
flutter analyze
```

To build an Android release APK:

```sh
cd habit_mastery_app
flutter build apk --release
```

On a new checkout, first create `habit_mastery_app/android/key.properties` with the team's existing signing values (keep the passwords private; the file is ignored by Git):

```properties
keyAlias=your-key-alias
keyPassword=your-key-password
storeFile=/absolute/path/to/your-release-key.jks
storePassword=your-store-password
```

The APK is written to `habit_mastery_app/build/app/outputs/flutter-apk/app-release.apk`. Release builds use the local properties in `habit_mastery_app/android/key.properties` and a keystore outside the repository at `~/.android/habit_mastery_release.jks`. The properties file is git-ignored; do not commit or publicly share either file. Back up the keystore and its password securely because future APK upgrades for this app need the same signing key.

## Project structure

```text
.
├── README.md
├── ARCHITECTURE.md
├── AI_FEATURE.md
└── habit_mastery_app/
    ├── lib/
    │   ├── database/       # SQLite schema, connection, settings storage
    │   ├── models/         # Habit, CheckIn, settings, derived weekly progress
    │   ├── screens/        # Dashboard, editor, details, history, settings
    │   ├── services/       # CRUD, validation, progress, Garden Guide
    │   ├── utils/          # Local calendar and week calculations
    │   └── widgets/        # Reusable habit, plant, and Garden Guide views
    └── test/               # Model, database/service, helper, and UI-flow tests
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for the data model, boundaries, validation rules, and known implementation gaps.

## Course and submission materials

- **Garden Guide documentation:** [AI_FEATURE.md](AI_FEATURE.md).
- **ClickUp board URL:** `TODO — add the team's shareable ClickUp board URL`.
- **Kanban evidence PDF:** `TODO — add Kanban_Contribution_Evidence.pdf at the repository root after assembling the four dated snapshots and contribution traces`.
- Include the approved proposal, completed signed statement, questions-only Word document, report, slide deck, tested APK, and video link in the final package as required by the course. These are not all stored in this repository yet.
- Keep the board URL and evidence PDF path above in sync with the final files. Do not backdate or recreate missing board history.

## Verification status

On October 31, 2026, `flutter test` passed all 89 tests and `flutter analyze` reported no issues. The release APK builds with the team release key; `apksigner` verified its APK Signature Scheme v2 signature. It installed and launched on a Pixel 10 Android emulator in airplane mode, with the dashboard rendered and the app process alive. This verifies one emulator cold launch offline, not two-device use or saved-record persistence across an offline restart. Check `git status` before packaging.
