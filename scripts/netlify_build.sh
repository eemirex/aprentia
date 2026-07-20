#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if [ ! -d "$FLUTTER_HOME/bin" ]; then
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --enable-web
flutter --version
flutter pub get

build_args=(web --release)

if [ -n "${SUPABASE_URL:-}" ]; then
  build_args+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
fi

if [ -n "${SUPABASE_ANON_KEY:-}" ]; then
  build_args+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
fi

if [ -n "${PRACTICE_API_URL:-}" ]; then
  build_args+=(--dart-define=PRACTICE_API_URL="$PRACTICE_API_URL")
fi

flutter build "${build_args[@]}"
