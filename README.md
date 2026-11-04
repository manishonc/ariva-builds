# ariva-builds

Public build runner for Ariva. It contains **no app code** — workflows check out the private `manishonc/ariva` repo with a token, build, and publish the results back to *that* repo's releases. It exists only because public repos get free GitHub-hosted macOS minutes.

| Workflow | Builds | Triggered by |
|---|---|---|
| `desktop.yml` | macOS desktop app | `repository_dispatch` from the private repo, or Run workflow |

Secret needed: `ARIVA_SOURCE_TOKEN` — fine-grained PAT on `manishonc/ariva` (contents: read & write).

Add new build targets (Android APK, etc.) as more workflows here.
