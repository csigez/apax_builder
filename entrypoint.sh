#!/usr/bin/env bash
set -e

if [ -n "$CONAN_REMOTE_NAME" ] && [ -n "$CONAN_REMOTE_URL" ]; then
  conan remote add "$CONAN_REMOTE_NAME" "$CONAN_REMOTE_URL" 2>/dev/null || \
    conan remote update "$CONAN_REMOTE_NAME" --url "$CONAN_REMOTE_URL"

  if [ -n "$CONAN_USER" ] && [ -n "$CONAN_PASSWORD" ]; then
    conan remote login "$CONAN_REMOTE_NAME" "$CONAN_USER" --password "$CONAN_PASSWORD"
  fi
fi

exec "$@"
