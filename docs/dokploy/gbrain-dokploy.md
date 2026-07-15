# Dokploy Deployment Guide

CI/CD pipeline to build a Docker image via GitHub Actions, publish to GitHub Container Registry (GHCR), and deploy on Dokploy.

## Architecture

```
GitHub (your fork of garrytan/gbrain)
  push any branch / tag v*
  GitHub Actions (.github/workflows/docker.yml)
  build + push multi-arch image (linux/amd64, linux/arm64)
  ghcr.io/<owner>/gbrain:sha-<commit>
  Dokploy pulls image, injects secrets at runtime
  gbrain container starts
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds image: Bun runtime + `bun install -g github:garrytan/gbrain#<ref>` + entrypoint |
| `docker-entrypoint.sh` | Runtime init: waits for Postgres, configures models, applies migrations, starts server |
| `.github/workflows/docker.yml` | CI/CD: builds and pushes image to GHCR on every branch push |
| `docker-compose.dokploy.yml` | Dokploy stack: postgres + gbrain service (pulls pre-built GHCR image) |

## Setup

### 1. GitHub Actions Variables

Go to your repository Settings > Secrets and variables > Actions > Variables:

```
Name:  GBRAIN_REF
Value: <commit-SHA-from-upstream-garrytan/gbrain>
```

This pins the gbrain version. Update it when you want to upgrade.

### 2. Dokploy Environment Variables

Set these in your Dokploy service environment (never hardcode them in files):

```
# Required
POSTGRES_PASSWORD=<strong-password>
OPENAI_API_KEY=<your-key>
GBRAIN_TAG=sha-<commit>     # from GitHub Actions build output
REPOSITORY_OWNER=<your-github-username>

# Optional (with defaults)
PORT=3131
GBRAIN_MODEL=openai:gpt-4o-mini
GBRAIN_EMBEDDING_MODEL=openai:text-embedding-3-small
GBRAIN_EMBEDDING_DIMENSIONS=1536
PUBLIC_URL=https://your-domain.example.com
OPENAI_BASE_URL=https://your-gateway.example.com/v1
GBRAIN_EMBED_ON_START=false
```

### 3. Dokploy Service Configuration

- Source: Docker GitHub
- Repository: your fork of `garrytan/gbrain`
- Branch: main (or your deployment branch)
- Compose file: `docker-compose.dokploy.yml`
- Environment variables: set all from the table above

The compose file uses `image:` (pull from GHCR) and never `build:` (no build on the server).

## Upgrade Flow

1. Pick a new commit SHA from `garrytan/gbrain` upstream
2. Update `GBRAIN_REF` in GitHub Variables
3. Manually trigger the workflow (or push a new commit)
4. Copy the tag `sha-<commit>` from the workflow output
5. Update `GBRAIN_TAG` in Dokploy environment
6. Dokploy redeploys with the new image

## Rollback

Set `GBRAIN_TAG` back to the previous `sha-<commit>` in Dokploy and redeploy.
