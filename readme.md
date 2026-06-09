
# SIMATIC AX / APAX Builder Container

Docker image for building **SIMATIC AX / APAX** projects in a reproducible Linux environment.

## What's inside the image

Based on `node:20-bookworm-slim`, pinned to `linux/amd64`:

| Component | Details |
|---|---|
| **APAX CLI** | Installed from local `apax.tgz`, updated via `apax self-update` at build time |
| **Conan 2** | Installed via `pip3`; remotes pre-configured from `remotes.json` |
| **Tools** | `bash`, `curl`, `git`, `ca-certificates`, `python3`, `pip` |
| **Working directory** | `/workspace` |

## Prerequisites

- Docker (Docker Desktop works)
- `apax.tgz` present in this directory (gitignored, must be provided locally)

## Conan remotes

Remotes are defined in `remotes.json` and registered into the image at build time:

```json
{
  "remotes": [
    { "name": "<remote-name>", "url": "https://<company>.jfrog.io/artifactory/api/conan/<repo>", "verify_ssl": true }
  ]
}
```

To add or remove remotes, edit `remotes.json` and rebuild the image.

## Build the image

```bash
docker build -f dockerfile -t simatic-ax-builder .
```

## Run an interactive shell

Copy `.env_template` to `.env`, fill in your credentials, then:

```bash
docker run --rm -it --env-file .env -v "$PWD:/workspace" simatic-ax-builder
```

On Apple Silicon, if you see a platform warning:

```bash
docker run --platform=linux/amd64 --rm -it --env-file .env -v "$PWD:/workspace" simatic-ax-builder
```

## Environment variables (`.env`)

`.env` is gitignored. Use `.env_template` as a starting point.

### Conan / JFrog Artifactory

| Variable | Description |
|---|---|
| `CONAN_USER` | JFrog username or e-mail |
| `CONAN_PASSWORD` | JFrog API key or password |

On startup, `entrypoint.sh` calls `conan remote login` for every remote in `/remotes.json` automatically.

### pip / PyPI (JFrog Artifactory)

| Variable | Description |
|---|---|
| `PIP_EXTRA_INDEX_HOST` | Host + path of the Artifactory PyPI repo, e.g. `<company>.jfrog.io/artifactory/api/pypi/<repo>/simple` |
| `PIP_EXTRA_INDEX_USER` | JFrog username or e-mail |
| `PIP_EXTRA_INDEX_TOKEN` | JFrog API key or password |

When set, `entrypoint.sh` writes `/root/.config/pip/pip.conf` so `pip install` resolves from both PyPI and the private index.

## Notes

### `@ax` scope error

If you see `No registry found for scope @ax`, configure the APAX registry inside the container:

```bash
apax config
apax login
```

## Typical workflow

1. Build the image.
2. Run the container with your project mounted into `/workspace`.
3. Run APAX commands inside the container, e.g. `apax install`, `apax run build`, etc.
