#!/usr/bin/env bash
set -uo pipefail

IMAGE="simatic-ax-builder"
PASS=0
FAIL=0
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

ok()   { printf "${GREEN}PASS${RESET}  %s\n" "$1"; PASS=$((PASS + 1)); }
fail() { printf "${RED}FAIL${RESET}  %s\n" "$1"; FAIL=$((FAIL + 1)); }

# ── 1. Build ──────────────────────────────────────────────────────────────────
echo "==> Building image..."
if docker build -f dockerfile -t "$IMAGE" . > /dev/null 2>&1; then
  ok "image builds"
else
  fail "image builds"
  echo "Build failed — aborting."
  exit 1
fi

# ── 2. Tool availability ──────────────────────────────────────────────────────
if docker run --rm "$IMAGE" conan --version 2>&1 | grep -q "Conan version 2"; then
  ok "conan 2 installed"
else
  fail "conan 2 installed"
fi

if docker run --rm "$IMAGE" bash -c "command -v apax" > /dev/null 2>&1; then
  ok "apax in PATH"
else
  fail "apax in PATH"
fi

for tool in python3 git curl; do
  if docker run --rm "$IMAGE" "$tool" --version > /dev/null 2>&1; then
    ok "$tool available"
  else
    fail "$tool available"
  fi
done

# ── 3. Entrypoint: no CONAN_* vars ───────────────────────────────────────────
if docker run --rm "$IMAGE" true > /dev/null 2>&1; then
  ok "entrypoint: starts without CONAN_* vars"
else
  fail "entrypoint: starts without CONAN_* vars"
fi

# ── 4. Entrypoint: remote is registered when URL vars are set ─────────────────
# Passes CONAN_REMOTE_* but no credentials — entrypoint should add the remote
# and then exec `conan remote list`, whose output we capture.
REMOTE_LIST=$(docker run --rm \
  -e CONAN_REMOTE_NAME=test-remote \
  -e CONAN_REMOTE_URL=https://fake.example.com/artifactory/api/conan/test \
  "$IMAGE" conan remote list 2>/dev/null) || true

if echo "$REMOTE_LIST" | grep -q "test-remote"; then
  ok "entrypoint: conan remote is registered"
else
  fail "entrypoint: conan remote is registered"
fi

# ── 5. Entrypoint: login is called when all credentials are provided ──────────
# Overrides the entrypoint to inject a fake `conan` binary that logs its
# arguments, then calls /entrypoint.sh manually so we can assert it invokes
# `conan remote login` with the expected credentials.
CONAN_LOG=$(docker run --rm \
  --entrypoint bash \
  -e CONAN_REMOTE_NAME=test-remote \
  -e CONAN_REMOTE_URL=https://fake.example.com/artifactory/api/conan/test \
  -e CONAN_USER=testuser \
  -e CONAN_PASSWORD=testpass \
  "$IMAGE" -c '
    mkdir -p /tmp/fakebin
    printf "#!/bin/sh\necho ARGS: \$@\n" > /tmp/fakebin/conan
    chmod +x /tmp/fakebin/conan
    export PATH=/tmp/fakebin:$PATH
    /entrypoint.sh true
  ' 2>/dev/null) || true

if echo "$CONAN_LOG" | grep -q "remote login"; then
  ok "entrypoint: conan remote login is called"
else
  fail "entrypoint: conan remote login is called"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
printf "Results: %d passed, %d failed\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
