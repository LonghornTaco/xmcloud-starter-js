# Local container stack

A lightweight Linux container stack for local development of the XM Cloud Next.js starter kits. Spins up:

- **Mockingbird** - a YAML-backed Sitecore CM shim that serves a GraphQL Layout Service from this repo's SCS-serialized YAML. Drop-in replacement for Experience Edge during local headless dev. Includes a Web UI for editing items/templates/renderings, a built-in Sitecore PowerShell Extensions (SPE) ISE, and a GraphQL Editor.
- **Rendering host** - a Next.js dev container that mounts one of the `examples/<starter>` directories.
- **Traefik** - reverse proxy with TLS, exposes the rendering host and Mockingbird Web UI on friendly hostnames.
- **windows-hosts-writer** - writes container hostnames to the Windows host's `hosts` file so devs can hit the friendly URLs from a browser.

The previous heavyweight Windows-based Sitecore CM/MSSQL/Solr stack has been removed. For local dev with a real CM, connect to a remote XM Cloud environment.

## Table of contents

- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Running the stack](#running-the-stack)
- [Switching starters](#switching-starters)
- [Endpoints](#endpoints)
- [Volumes](#volumes)
- [Stopping](#stopping)
- [Cleaning up](#cleaning-up)

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows, running the Linux engine
- PowerShell 7+ (the helper scripts assume `pwsh`)
- Node.js LTS on the host (only needed if you also want to run a starter natively without the rendering container)

## Configuration

All configuration lives in `local-containers/.env`. Before starting the stack, set:

| Variable | Purpose |
|---|---|
| `STARTER_PATH` | Path (relative to `local-containers/`) of the starter the rendering container should mount. Defaults to `../examples/basic-nextjs`. |
| `NEXT_PUBLIC_DEFAULT_SITE_NAME` | Sitecore site name. Must match a site defined in the Mockingbird-mounted serialization tree (Site Grouping item with a populated `HostName` field). |

The other variables in `.env` have sensible defaults for local dev.

Mockingbird derives its site list from Site Grouping items in the corpus at boot, so there is no per-site env pin. The SDK's multisite proxy passes `?site=<name>` on each layout query; Mockingbird uses that (with `Host:` header as a fallback) to scope the response.

## Running the stack

From the repo root, in an elevated PowerShell:

```ps1
# One-time setup: generate Traefik TLS certificates.
./local-containers/scripts/init.ps1

# Build and start.
./local-containers/scripts/up.ps1
```

`init.ps1` downloads `mkcert` if needed, installs the local root CA, and produces `cert.pem` / `key.pem` in `docker/traefik/certs/` covering the rendering host and Mockingbird hostnames. Run with `-RecreateCerts` to regenerate.

`up.ps1` builds the rendering container, starts the stack, and waits for the Mockingbird route to come up via Traefik.

## Switching starters

The rendering container mounts one starter at a time. To target a different starter:

1. Update `.env`:
   - `STARTER_PATH=../examples/<starter>`
   - `NEXT_PUBLIC_DEFAULT_SITE_NAME=<site>`
2. Recreate the affected services:
   ```ps1
   docker compose up -d --force-recreate rendering
   ```

The `rendering-node-modules` named volume is shared across starters - it is not destroyed on `--force-recreate`. If two starters have different dependency trees and you switch between them, wipe the volume so `npm install` runs against the new `package.json`:

```ps1
docker compose down
docker volume rm xmcloud-starter-js_rendering-node-modules
docker compose up -d
```

## Endpoints

| What | URL |
|---|---|
| Rendering host | https://nextjs.xmc-starter-js.localhost |
| Mockingbird Web UI | https://mockingbird.xmc-starter-js.localhost |
| Mockingbird SPE ISE | https://mockingbird.xmc-starter-js.localhost/scripts |
| Mockingbird Layout Service | https://mockingbird.xmc-starter-js.localhost/sitecore/api/graph/edge |
| Mockingbird indexing status | https://mockingbird.xmc-starter-js.localhost/api/status |
| Traefik dashboard | http://localhost:8079 |

## Volumes

| Mount | Host path (default) | Purpose |
|---|---|---|
| Mockingbird `/app/data/sitecore.json` | `../sitecore.json` | SCS root config |
| Mockingbird `/app/data/serialization` | `../authoring/items` | Dev-authored templates, renderings, layouts |
| Mockingbird `/app/data/content` | `./mockingbird-content` | Optional second SCS root for content-item YAMLs not in the repo |
| Mockingbird `/app/data/cache` | `./mockingbird-cache` | Engine-internal index cache. Safe to delete; rebuilds on boot |
| Rendering `/app` | `../examples/<starter>` | The starter source |
| Rendering `/app/node_modules` | named volume `rendering-node-modules` | Linux-native npm install, isolated from host |

## Stopping

```ps1
./local-containers/scripts/down.ps1
```

## Cleaning up

To wipe Mockingbird's index cache (safe; rebuilds on next boot):

```ps1
./local-containers/docker/clean.ps1
```
