#!/usr/bin/env bash
set -e

if [ -n "$PIP_EXTRA_INDEX_HOST" ] && [ -n "$PIP_EXTRA_INDEX_USER" ] && [ -n "$PIP_EXTRA_INDEX_TOKEN" ]; then
  mkdir -p /root/.config/pip
  cat > /root/.config/pip/pip.conf <<EOF
[global]
index-url = https://pypi.org/simple
extra-index-url = https://${PIP_EXTRA_INDEX_USER}:${PIP_EXTRA_INDEX_TOKEN}@${PIP_EXTRA_INDEX_HOST}
EOF
fi

if [ -n "$CONAN_USER" ] && [ -n "$CONAN_PASSWORD" ]; then
  while IFS= read -r remote; do
    conan remote login "$remote" "$CONAN_USER" --password "$CONAN_PASSWORD"
  done < <(python3 -c "import json; [print(r['name']) for r in json.load(open('/remotes.json'))['remotes']]")
fi

exec "$@"
