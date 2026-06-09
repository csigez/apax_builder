
# SIMATIC AX / APAX Builder Container

This repository contains a small Docker image you can use as a repeatable build environment for **SIMATIC AX / APAX** projects.

The image is intended to:

- provide a minimal Linux environment with **Node.js** and **bash**
- include the **APAX CLI** (installed from the local `apax.tgz`)
- run as **Linux x64 (`linux/amd64`)**, so you get consistent behavior across hosts (including Apple Silicon)

## What’s inside the image

The Dockerfile is based on `node:20-bookworm-slim` and installs a few small utilities commonly needed during builds:

- `bash`
- `curl`
- `git`
- `ca-certificates`
- `python3` + `pip` (required for Conan)

It also:

- sets the working directory to `/workspace`
- copies `apax.tgz` into the image and installs it via `npm install -g`
- installs **Conan 2** via pip
- runs `entrypoint.sh` on startup to auto-configure the Conan remote

## Prerequisites

- Docker (Docker Desktop is fine)
- `apax.tgz` present in this repository (the Dockerfile expects it)

## Build the image

From this repository directory:

```bash
docker build -f dockerfile -t simatic-ax-builder .
```

## Run an interactive shell

Mount your project into `/workspace` and pass in the credentials from `.env`:

```bash
docker run --rm -it --env-file .env -v "$PWD:/workspace" simatic-ax-builder
```

You should land in a shell where you can run:

```bash
apax -h
```

## Running on Apple Silicon (M1/M2/M3)

The Dockerfile pins the image to `linux/amd64`. Docker Desktop will run it via emulation.

If you still see a platform warning at runtime, you can force the platform explicitly:

```bash
docker run --platform=linux/amd64 --rm -it --env-file .env -v "$PWD:/workspace" simatic-ax-builder
```

## Conan / JFrog Artifactory

The container includes **Conan 2** and configures a remote automatically on startup if the following variables are set in `.env`:

| Variable | Description |
|---|---|
| `CONAN_REMOTE_NAME` | Logical name of the remote, e.g. `artifactory` |
| `CONAN_REMOTE_URL` | Full URL, e.g. `https://<company>.jfrog.io/artifactory/api/conan/<repo>` |
| `CONAN_USER` | JFrog username or e-mail |
| `CONAN_PASSWORD` | JFrog API key or password |

Fill these in `.env` (already gitignored) before running the container. The `entrypoint.sh` script calls `conan remote add` and `conan remote login` automatically so you can immediately run `conan install` inside the container.

## Notes / common issues

### Registry configuration for `@ax` scope

If you see an error like:

> No registry found for scope @ax. Please add a registry to the apax.yml or global config.

you need to configure an APAX registry for your project or your global APAX config.

Typical next steps inside the container:

```bash
apax config
apax login
```

## Typical workflow

1. Build the image.
2. Run the container with your project mounted into `/workspace`.
3. Run APAX commands inside the container, e.g. `apax install`, `apax run ...`, etc.

