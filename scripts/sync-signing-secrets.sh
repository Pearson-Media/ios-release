#!/bin/bash
# Copies the shared Apple signing secrets from Infisical into each app repo's
# GitHub secrets. Run it after renewing the Development certificate or the App
# Store Connect key. Values go from Infisical to GitHub through a pipe and are
# never printed.
#
# Needs: the infisical CLI logged in, gh logged in with access to every repo.
# Usage: scripts/sync-signing-secrets.sh            (all repos below)
#        scripts/sync-signing-secrets.sh owner/repo (just one)
set -euo pipefail

# Source of truth: GradeThread's Infisical project, prod, path /.
INFISICAL_PROJECT_ID="49de5bc0-9e94-4e36-83d9-7f99979a1b47"
INFISICAL_ENV="prod"

# GitHub secret name in each app repo  <-  name in Infisical
MAP=(
  "IOS_ASC_KEY_ID:APP_STORE_CONNECT_API_KEY_ID"
  "IOS_ASC_ISSUER_ID:APP_STORE_CONNECT_API_ISSUER_ID"
  "IOS_ASC_KEY_BASE64:APP_STORE_CONNECT_API_KEY_BASE64"
  "IOS_DEV_CERT_BASE64:BUILD_CERTIFICATE_BASE64"
  "IOS_DEV_CERT_PASSWORD:P12_PASSWORD"
  "IOS_TEAM_ID:APPLE_TEAM_ID"
)

# GradeThread reads Infisical directly, so it is not listed.
REPOS=(
  dj-pearson/wellvo
  dj-pearson/Last_Logged
  dj-pearson/Seddly
  dj-pearson/Loci
  dj-pearson/desmoines-ai-pulse
  Pearson-Media/Printyx
  Pearson-Media/project-profit-radar
)
if [ "$#" -gt 0 ]; then REPOS=("$@"); fi

for pair in "${MAP[@]}"; do
  gh_name="${pair%%:*}"; inf_name="${pair#*:}"
  value=$(infisical secrets get "$inf_name" --plain --projectId="$INFISICAL_PROJECT_ID" --env="$INFISICAL_ENV" --path=/ 2>/dev/null || true)
  if [ -z "$value" ]; then
    echo "Missing in Infisical: $inf_name. Nothing was changed for it." >&2
    exit 1
  fi
  for repo in "${REPOS[@]}"; do
    printf '%s' "$value" | gh secret set "$gh_name" --repo "$repo" >/dev/null
    echo "set $gh_name on $repo"
  done
  unset value
done
