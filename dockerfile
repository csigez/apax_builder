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

COPY apax.tgz .
COPY entrypoint.sh /entrypoint.sh

RUN npm install -g ./apax.tgz \
 && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
