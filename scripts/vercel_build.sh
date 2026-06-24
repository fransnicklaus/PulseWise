#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  flutter_version="${FLUTTER_VERSION:-3.24.4}"
  cache_root="${VERCEL_CACHE_DIR:-$PWD/.vercel-cache}"
  flutter_home="$cache_root/flutter"

  if [ ! -x "$flutter_home/bin/flutter" ]; then
    rm -rf "$flutter_home"
    git clone --depth 1 --branch "$flutter_version" \
      https://github.com/flutter/flutter.git "$flutter_home"
  fi

  export PATH="$flutter_home/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get

flutter_args=(
  build
  web
  --release
)

dart_define_keys=(
  API_BASE_URL
  GOOGLE_WEB_CLIENT_ID
  GOOGLE_CLIENT_ID
  GOOGLE_SERVER_CLIENT_ID
  GOOGLE_WEB_CLIENT_ID_PLAY_STORE
  CLOUDINARY_FOLDER
)

for key in "${dart_define_keys[@]}"; do
  value="${!key:-}"
  if [ -z "${value//[[:space:]]/}" ]; then
    continue
  fi

  flutter_args+=("--dart-define=$key=$value")
done

flutter "${flutter_args[@]}"
