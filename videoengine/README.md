# VideoEngine builds

VideoEngine (`manishonc/VideoEngine`, private) is a separate platform from Ariva. This repo builds
its Docker images for the same reason it builds Ariva's apps: free GitHub-hosted runners. Builds
also stay off the production server. This folder holds the docs. The workflows themselves have to
live in `.github/workflows/` (GitHub runs them only from there), and their names start with
`videoengine-`.

| Workflow | Builds | Triggered by |
|---|---|---|
| `videoengine-render.yml` | Render worker image (`apps/studio/render/deployment/Dockerfile`, linux/amd64) → `ghcr.io/manishonc/videoengine-render` | `repository_dispatch` `videoengine-render-build` from VideoEngine (`.github/workflows/render-image.yml`), or Run workflow |

## Image and tags

- `ghcr.io/manishonc/videoengine-render`, a **private** package. The image contains VideoEngine's
  code, so it must never be made public. GitHub cannot make a public package private again.
- `:main` is the latest build of `main`, and Dokploy pulls this tag.
- `:sha-<commit>` is fixed for every build. Use it to roll back: set Dokploy's image to it and
  deploy.
- `:buildcache` is the layer cache. It lives in the private package, not the Actions cache,
  because pull requests from forks can read the Actions cache of a public repo.
- `:seed` is the owner's placeholder that proves the package exists (see below).

## One-time setup

1. **Seed the package, private.** A package first pushed by this public repo's `GITHUB_TOKEN`
   can come out public, so the workflow never creates it. It stops if `:seed` is missing or the
   package can be pulled anonymously. On your own machine, with a classic PAT that has
   `write:packages`:

   ```sh
   docker login ghcr.io -u manishonc            # paste the PAT as the password
   docker pull --platform linux/amd64 busybox:1.37
   docker tag busybox:1.37 ghcr.io/manishonc/videoengine-render:seed
   docker push ghcr.io/manishonc/videoengine-render:seed
   ```

   Then check the visibility on
   https://github.com/users/manishonc/packages/container/package/videoengine-render (Package
   settings). It must say **Private**.
2. **Give this repo write access to the package.** Package settings → Manage Actions access →
   add `manishonc/ariva-builds` with role **Write**.
3. **Secrets on this repo:**

   | Secret | What |
   |---|---|
   | `VIDEOENGINE_SOURCE_TOKEN` | Fine-grained PAT on `manishonc/VideoEngine` only, **Contents: read**. Nothing is published back to VideoEngine. |
   | `DOKPLOY_RENDER_DEPLOY_HOOK` | The Render app's deploy webhook URL (Dokploy → VideoEngine → Render → Deployments). Anyone with it can redeploy Render. Without it the step is skipped, and you deploy by hand. |

4. **Secret on VideoEngine:** `ARIVA_BUILDS_TOKEN`, a fine-grained PAT on
   `manishonc/ariva-builds` with **Contents: read & write** (needed to send `repository_dispatch`).
5. **Dokploy, the Render app (`videoengine-render-oedqbw`):** Provider → **Docker**. Docker Image
   `ghcr.io/manishonc/videoengine-render:main`, Registry URL `ghcr.io`, Username `manishonc`,
   Password: a classic PAT with only `read:packages` (GHCR does not take fine-grained PATs).
   Keep Auto Deploy on, since the webhook needs it. Leave the env, the resource limits and
   "Create Environment File" (off) as they are. Switching the provider also stops Dokploy
   building Render on the server.
