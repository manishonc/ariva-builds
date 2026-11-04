# ariva-builds

Public build runner for Ariva. It contains **no app code** — workflows check out the private `manishonc/ariva` repo with a token, build, and publish the results back to *that* repo's releases. It exists only because public repos get free GitHub-hosted runner minutes (private-repo macOS minutes bill at 10x).

| Workflow | Builds | Triggered by |
|---|---|---|
| `desktop.yml` | macOS desktop app (DMG/zip) → `desktop-latest` / `desktop-v*` | `repository_dispatch` `desktop-build` from the private repo, or Run workflow |
| `android.yml` | Android APK of `apps/mobile` (Expo) → `android-latest` / `android-v*` | `repository_dispatch` `android-build` from the private repo, or Run workflow |
| `messages.yml` | Ariva Messages APK (`apps/messaging/android`, native Kotlin SMS app) → `messages-latest` / `messages-v*` | `repository_dispatch` `messages-build` from the private repo, or Run workflow |

Secret needed: `ARIVA_SOURCE_TOKEN` — fine-grained PAT on `manishonc/ariva` (contents: read & write).

Ariva Messages is signed with the user's **release keystore** (a default SMS app must only ever be updated by the same key), so `messages.yml` also needs `ARIVA_MESSAGES_KEYSTORE_B64` (base64 of the keystore), `ARIVA_MESSAGES_KEYSTORE_PASSWORD`, `ARIVA_MESSAGES_KEY_ALIAS` and `ARIVA_MESSAGES_KEY_PASSWORD`. Optional repo variables: `ARIVA_MESSAGES_CERT_SHA256` (pins the expected signer; the build fails on any other) and `ARIVA_FCM_{APP_ID,PROJECT_ID,API_KEY,SENDER_ID}` (push config; unset = push off).

Releases always land on the **private** repo. The Android (Expo) APK is signed with the stock Expo debug key (same as local builds), so no signing secret is needed; it is for side-loading, not the Play Store.

## Naming

Every target follows the same pattern, so releases read the same on every platform:

| Thing | Pattern | macOS | Android | Messages |
|---|---|---|---|---|
| Workflow file | `<target>.yml` | `desktop.yml` | `android.yml` | `messages.yml` |
| Workflow name | `Ariva <Platform> build` | Ariva macOS build | Ariva Android build | Ariva Messages build |
| Dispatch event | `<target>-build` | `desktop-build` | `android-build` | `messages-build` |
| Rolling tag (prerelease) | `<target>-latest` | `desktop-latest` | `android-latest` | `messages-latest` |
| Rolling title | `Ariva <Platform> (latest build)` | Ariva macOS (latest build) | Ariva Android (latest build) | Ariva Messages (latest build) |
| Versioned tag | `<target>-v<version>` | `desktop-v0.3.0` | `android-v1.1.0` | `messages-v0.2.0` |
| Versioned title | `Ariva <Platform> <version>` | Ariva macOS 0.3.0 | Ariva Android 1.1.0 | Ariva Messages 0.2.0 |

`<Platform>` is the platform's proper name (macOS, Android, Windows, iOS, Linux), or a separate app's product name (Messages), never a bare "Ariva". Tags keep the short target slug because links and updaters point at them; don't rename an existing tag.

Add new build targets as more workflows here, following the table.
