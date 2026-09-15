# Aprentia

> A Flutter learning companion for building practical prompting skills through short lessons, AI-assisted practice, streaks, and progress tracking.

Aprentia is a portfolio project exploring a focused learning experience rather than a generic course catalogue. It gives a learner a low-friction path: start as a guest, work through structured lessons, submit practice answers, receive feedback, and build momentum through progress and badge mechanics.

## What is implemented

- Guided lessons on prompting fundamentals and workflows
- Practice exercises loaded from local content
- A structured practice-feedback model: score, written feedback, and an improved answer
- Guest-first onboarding with local persistence
- XP, streak, hearts, completed lessons, practice history, and achievement badges
- Profile preferences for learner goal and skill level
- Optional Supabase-backed authentication with an anonymous/local fallback
- Responsive Flutter UI built with Material 3

## Product flow

```text
Open app
  → continue as a guest
  → complete a lesson or practice prompt
  → receive feedback
  → earn progress and badges
  → optionally upgrade to email authentication when Supabase is configured
```

The application keeps a learner productive without requiring an account first. When Supabase is unavailable, the local authentication service and `shared_preferences` preserve the demo experience.

## Architecture

```text
lib/
├── main.dart                         # App root, theme, splash transition
└── features/
    ├── shell/                         # App state, navigation, local persistence
    ├── auth/                          # Auth abstraction, local and Supabase adapters
    ├── courses/                       # In-app lesson content and course view
    ├── practice/                      # Practice models, prompts, grading UI/service
    ├── achievements/                  # Badge definitions and progress view
    └── profile/                       # Learner preferences and account upgrade UI
```

### Design decisions

- **Guest-first experience:** The app remains explorable without creating an account or configuring cloud services.
- **Authentication abstraction:** `AuthService` keeps the UI independent of the local guest implementation and the optional Supabase implementation.
- **Local persistence:** Progress is stored with `shared_preferences` for a fast, credential-free demo. It is not a substitute for synced, durable learner records.
- **Structured feedback contract:** Practice feedback is represented as a score, feedback, and improved answer rather than raw chat text, making it easier for the UI to present consistently.

## AI-feedback security note

The repository currently contains an experimental `OpenAIPracticeService` that reads `OPENAI_API_KEY` from client-side configuration for local development.

**Do not place an OpenAI API key in a deployed Flutter web or mobile build.** Client bundles can expose it. Before production use, move the model call behind a server-side endpoint or trusted backend function that:

1. stores the provider key only on the server;
2. authenticates and rate-limits callers;
3. validates request and response schemas;
4. records safe observability data; and
5. applies abuse, cost, and prompt-injection controls.

This is an intentional limitation to discuss openly in a portfolio review, not a production-ready AI integration.

## Run locally

### Prerequisites

- Flutter SDK compatible with Dart `^3.10.7`
- A device, emulator, or supported browser
- Optional: a Supabase project for email authentication
- Optional, local-only: an OpenAI key for experimenting with the practice-feedback service

### Install

```bash
git clone https://github.com/eemirex/aprentia.git
cd aprentia
flutter pub get
flutter run
```

For a browser preview:

```bash
flutter run -d chrome
```

## Optional Supabase authentication

Aprentia detects whether Supabase has been initialized. Without it, the application uses its local guest authentication flow.

To connect Supabase, initialize `SupabaseFlutter` during application startup with your project URL and publishable/anon key, then configure the relevant email authentication settings in Supabase. Keep secrets out of source control.

## Quality checks

Run these before opening a pull request:

```bash
flutter analyze
flutter test
flutter build web --release
```

## Current limitations and next steps

- Learner progress is local to the device; it is not yet a synced multi-device learning record.
- The AI grading integration must move server-side before deployment.
- The grading response needs stronger schema validation and robust handling for malformed model output.
- The project needs a deployed demo and automated CI verification.
- The next product increment would add server-backed progress, secure AI feedback, and evaluation of grading quality against a small labeled practice dataset.

## Why this project matters

Aprentia is an exercise in making AI learning practical and safe: the product is intentionally simple, the learning loop is visible, and the boundary between a portfolio prototype and a production system is explicit.

Built by [Emmanuel Emirex](https://github.com/eemirex).
