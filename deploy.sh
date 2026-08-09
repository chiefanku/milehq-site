#!/usr/bin/env bash
# Publish the Milehq marketing/legal site to Cloudflare Pages.
#
#   ./deploy.sh
#
# Canonical host is milehq.hbadgerlabs.com (custom domain on the "milehq"
# Pages project, Honey Badger Labs Cloudflare account). The App Store listing
# points at /privacy and /support, so those two must never 404 — Apple
# re-fetches the privacy URL for the life of the app, not just at review.
#
# Needs CLOUDFLARE_API_TOKEN with Account -> Cloudflare Pages -> Edit.
set -euo pipefail

ACCOUNT_ID=1f08b82381e2626b60ea8c68f91e4378
PROJECT=milehq
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST="$ROOT/.work/dist"

: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN is not set}"

# Ship a clean tree — no .git, no workflow files, no scratch.
rm -rf "$DIST"
mkdir -p "$DIST"
cp "$ROOT"/*.html "$ROOT"/style.css "$DIST/"

CLOUDFLARE_ACCOUNT_ID="$ACCOUNT_ID" CI=1 \
  npx --yes wrangler@4 pages deploy "$DIST" \
    --project-name="$PROJECT" --branch=main --commit-dirty=true

echo
# Both hosts serve this project. kiro.* is canonical; milehq.* is still the
# hostname registered on the App Store listing and must keep answering until
# that is repointed, so a break in either one is a problem.
for host in kiro.hbadgerlabs.com milehq.hbadgerlabs.com; do
  for path in "" privacy support; do
    code=$(curl -sL -o /dev/null -w '%{http_code}' --max-time 20 "https://$host/$path")
    printf '  %-24s /%-8s -> %s\n' "$host" "$path" "$code"
  done
done
