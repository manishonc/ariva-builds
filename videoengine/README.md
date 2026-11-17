# VideoEngine builds

VideoEngine (`manishonc/VideoEngine`, private) is a separate platform from Ariva. This repo builds
its Docker images to save build cost: GitHub-hosted runners are free for a public repo, and the
production server only pulls the finished image. This folder holds the docs. The workflows have to
live in `.github/workflows/` (GitHub runs them only from there), and their names start with
`videoengine-`.

| Workflow | Builds | Triggered by |
|---|---|---|
| `videoengine-render.yml` | Render worker image (`apps/studio/render/deployment/Dockerfile`, linux/amd64) → `ghcr.io/manishonc/videoengine-render` | `repository_dispatch` `videoengine-render-build` from VideoEngine (`.github/workflows/render-image.yml`), or Run workflow |
| `videoengine-agent.yml` | Studio agent image (`apps/studio/agent/deployment/Dockerfile`, linux/amd64) → `ghcr.io/manishonc/videoengine-agent` | `repository_dispatch` `videoengine-agent-build` from VideoEngine (`.github/workflows/agent-image.yml`), or Run workflow |

Both workflows are the same apart from the names; a change to one usually belongs in the other.

## Images and tags

- `ghcr.io/manishonc/videoengine-render` is **public** (owner's choice, 17 Nov 2026), and
  `ghcr.io/manishonc/videoengine-agent` is public the same way: anyone can pull them, so the render
  worker's and the agent's code (its instructions included) is readable. They hold no secrets;
  the env lives in Dokploy.
- `:main` is the latest build, and Dokploy pulls this tag.
- `:sha-<commit>` is fixed for every build. Roll back by setting Dokploy's image to it.
- `:buildcache` is the layer cache.

## Setup

Secrets on this repo:

| Secret | What |
|---|---|
| `VIDEOENGINE_SOURCE_TOKEN` | Fine-grained PAT on `manishonc/VideoEngine` only, **Contents: read**, to check out its code. Used by both workflows. |
| `DOKPLOY_RENDER_DEPLOY_HOOK` | The Render app's deploy webhook URL (Dokploy → VideoEngine → Render → Deployments). Without it, the step is skipped. |
| `DOKPLOY_AGENT_DEPLOY_HOOK` | The Agent app's deploy webhook URL (Dokploy → VideoEngine → Agent → Deployments). Without it, the step is skipped. |

On VideoEngine: `ARIVA_BUILDS_TOKEN`, a fine-grained PAT on `manishonc/ariva-builds` with
**Contents: read and write**, so it can send the `repository_dispatch`.

Each package must give this repo **Write** (package settings → Manage Actions access).
`videoengine-render` needed it set by hand, because it was first pushed by hand. A package first
pushed by this repo's own workflow (`videoengine-agent`) is linked to the repo and gets Write by
itself. A new package starts **private**: make it public in its package settings → Change
visibility, or Dokploy cannot pull it without a registry login.

Dokploy, each app (Render, Agent): Provider → Docker, image `ghcr.io/manishonc/videoengine-<part>:main`,
no registry login (the image is public), Auto Deploy on (that is what the webhook triggers).

Dokploy runs one deployment at a time. A redeploy requested while another app is building
waits in the queue.
