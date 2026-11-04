# ariva-builds

Public build runner for Ariva. It contains **no app code** — workflows check out the private `manishonc/ariva` repo with a token, build, and publish the results back to *that* repo's releases. It exists only because public repos get free GitHub-hosted runner minutes (private-repo macOS minutes bill at 10x).

| Workflow | Builds | Triggered by |
|---|---|---|
| `desktop.yml` | macOS desktop app (DMG/zip) → `desktop-latest` / `desktop-v*` | `repository_dispatch` `desktop-build` from the private repo, or Run workflow |
| `android.yml` | Android APK of `apps/mobile` (Expo) → `android-latest` / `android-v*` | `repository_dispatch` `android-build` from the private repo, or Run workflow |

Secret needed: `ARIVA_SOURCE_TOKEN` — fine-grained PAT on `manishonc/ariva` (contents: read & write).

Releases always land on the **private** repo. The Android APK is signed with the stock Expo debug key (same as local builds), so no signing secret is needed; it is for side-loading, not the Play Store.

Add new build targets as more workflows here.
