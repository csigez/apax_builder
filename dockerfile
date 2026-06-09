FROM --platform=linux/amd64 node:20-bookworm-slim
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
  bash \
  ca-certificates \
  curl \
  git \
  python3 \
  python3-pip \
 && pip3 install --break-system-packages conan \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY remotes.json /remotes.json
COPY apax.tgz .
COPY entrypoint.sh /entrypoint.sh

RUN python3 -c "import json,subprocess; [subprocess.run(['conan','remote','add',r['name'],r['url']],check=True) for r in json.load(open('/remotes.json'))['remotes']]" \
 && npm install -g ./apax.tgz \
 && apax self-update \
 && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
