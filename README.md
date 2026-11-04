# ariva-builds

Public build runner for Ariva. It contains **no app code** — workflows check out the private `manishonc/ariva` repo with a token, build, and publish the results back to *that* repo's releases. It exists only because public repos get free GitHub-hosted runner minutes (private-repo macOS minutes bill at 10x).

| Workflow | Builds | Triggered by |
|---|---|---|
| `desktop.yml` | macOS desktop app (DMG/zip) → `desktop-latest` / `desktop-v*` | `repository_dispatch` `desktop-build` from the private repo, or Run workflow |
| `android.yml` | Android APK of `apps/mobile` (Expo) → `android-latest` / `android-v*` | `repository_dispatch` `android-build` from the private repo, or Run workflow |

Secret needed: `ARIVA_SOURCE_TOKEN` — fine-grained PAT on `manishonc/ariva` (contents: read & write).

Releases always land on the **private** repo. The Android APK is signed with the stock Expo debug key (same as local builds), so no signing secret is needed; it is for side-loading, not the Play Store.

## Naming

Every target follows the same pattern, so releases read the same on every platform:

| Thing | Pattern | macOS | Android |
|---|---|---|---|
| Workflow file | `<target>.yml` | `desktop.yml` | `android.yml` |
| Workflow name | `Ariva <Platform> build` | Ariva macOS build | Ariva Android build |
| Dispatch event | `<target>-build` | `desktop-build` | `android-build` |
| Rolling tag (prerelease) | `<target>-latest` | `desktop-latest` | `android-latest` |
| Rolling title | `Ariva <Platform> (latest build)` | Ariva macOS (latest build) | Ariva Android (latest build) |
| Versioned tag | `<target>-v<version>` | `desktop-v0.3.0` | `android-v1.1.0` |
| Versioned title | `Ariva <Platform> <version>` | Ariva macOS 0.3.0 | Ariva Android 1.1.0 |

`<Platform>` is the platform's proper name (macOS, Android, Windows, iOS, Linux), never a bare "Ariva". Tags keep the short target slug because links and updaters point at them; don't rename an existing tag.

Add new build targets as more workflows here, following the table.
