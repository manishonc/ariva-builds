#!/usr/bin/env bash
# Mirrors build files to Cloudflare R2 and writes release-notes lines with a
# 7-day signed download link for each.
#
# Why: GitHub's release-asset host (release-assets.githubusercontent.com) is
# throttled on some networks (Airtel India measured at 6-26 KB/s) while R2
# serves the same file at ~9 MB/s. The release on the PRIVATE repo stays the
# source of truth; R2 is only a faster door to the same bytes.
#
# usage: r2-mirror.sh <target> <build-id> <notes-out> <file>...
#   target    desktop | android | messages (the key prefix)
#   build-id  unique per build (the version), so old links keep working
#   notes-out file to write the notes lines to (empty when R2 is not set up)
#
# Env: R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY (secrets),
#      R2_BUCKET (default ariva-builds). Missing credentials skip the mirror.
#
# This repo's logs are public: the signed URLs are masked and only ever
# written to the notes file, which goes into the private repo's release.
set -euo pipefail

target="$1" id="$2" notes="$3"
shift 3
: > "$notes"

[[ "$target" =~ ^[a-z]+$ ]] || { echo "bad target"; exit 1; }
[[ "$id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "bad build id"; exit 1; }

if [ -z "${R2_ACCOUNT_ID:-}" ] || [ -z "${R2_ACCESS_KEY_ID:-}" ] || [ -z "${R2_SECRET_ACCESS_KEY:-}" ]; then
  echo "::notice title=R2 mirror skipped::R2 secrets are not set on this repo; downloads use GitHub only."
  exit 0
fi

export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION=auto AWS_EC2_METADATA_DISABLED=true
# Newer AWS CLIs add checksum headers R2 does not need; only send them when required.
export AWS_REQUEST_CHECKSUM_CALCULATION=when_required AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
endpoint="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
bucket="${R2_BUCKET:-ariva-builds}"
ttl=604800 # 7 days, the longest a SigV4 link may live
expires="$(python3 -c "import datetime as d;print((d.datetime.now(d.timezone.utc)+d.timedelta(seconds=$ttl)).strftime('%Y-%m-%dT%H:%M:%SZ'))")"

for f in "$@"; do
  name="$(basename "$f")"
  key="$target/$id/$name"
  aws s3 cp "$f" "s3://$bucket/$key" --endpoint-url "$endpoint" --only-show-errors
  url="$(aws s3 presign "s3://$bucket/$key" --expires-in "$ttl" --endpoint-url "$endpoint")"
  echo "::add-mask::$url"
  # Machine-readable line for the Ariva builds pane, then one for people.
  printf '<!-- r2 %s %s %s -->\n' "$name" "$expires" "$url" >> "$notes"
  printf -- '- ⚡ [Fast download: %s](%s) (link valid until %s)\n' "$name" "$url" "${expires%T*}" >> "$notes"
  echo "R2 mirror: $key"
done
