# VideoEngine builds

VideoEngine (`manishonc/VideoEngine`, private) is a separate platform from Ariva. This repo builds
its Docker images to save build cost: GitHub-hosted runners are free for a public repo, and the
production server only pulls the finished image. This folder holds the docs. The workflows have to
live in `.github/workflows/` (GitHub runs them only from there), and their names start with
`videoengine-`.

| Workflow | Builds | Triggered by |
|---|---|---|
| `videoengine-render.yml` | Render worker image (`apps/studio/render/deployment/Dockerfile`, linux/amd64) → `ghcr.io/manishonc/videoengine-render` | `repository_dispatch` `videoengine-render-build` from VideoEngine (`.github/workflows/render-image.yml`), or Run workflow |

## Image and tags

- `ghcr.io/manishonc/videoengine-render` is **public** (owner's choice, 17 Nov 2026): anyone can
  pull it, so the render worker's code is readable. It holds no secrets; the env lives in
  Dokploy.
- `:main` is the latest build, and Dokploy pulls this tag.
- `:sha-<commit>` is fixed for every build. Roll back by setting Dokploy's image to it.
- `:buildcache` is the layer cache.

## Setup

Secrets on this repo:

| Secret | What |
|---|---|
| `VIDEOENGINE_SOURCE_TOKEN` | Fine-grained PAT on `manishonc/VideoEngine` only, **Contents: read**, to check out its code. |
| `DOKPLOY_RENDER_DEPLOY_HOOK` | The Render app's deploy webhook URL (Dokploy → VideoEngine → Render → Deployments). Without it, the step is skipped. |

On VideoEngine: `ARIVA_BUILDS_TOKEN`, a fine-grained PAT on `manishonc/ariva-builds` with
**Contents: read and write**, so it can send the `repository_dispatch`.

The package must give this repo **Write** (package settings → Manage Actions access), because it
was first pushed by hand.

Dokploy, the Render app: Provider → Docker, image `ghcr.io/manishonc/videoengine-render:main`,
no registry login (the image is public), Auto Deploy on.

Dokploy runs one deployment at a time. A redeploy requested while another app is building
waits in the queue.
