#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_URL:?e.g. https://github.com/your-org/your-repo OR https://github.com/your-org}"
: "${GITHUB_PAT:?personal access token with 'manage_runners:org' for org, or 'repo' for repo-scope}"
: "${RUNNER_NAME:=container-${HOSTNAME}}"
: "${RUNNER_LABELS:=self-hosted,linux,x64}"
: "${RUNNER_WORKDIR:=/_work}"

api_base="https://api.github.com"
if [[ "$RUNNER_URL" =~ https://github.com/([^/]+)/([^/]+)$ ]]; then
  owner="${BASH_REMATCH[1]}"; repo="${BASH_REMATCH[2]}"
  token_url="$api_base/repos/${owner}/${repo}/actions/runners/registration-token"
elif [[ "$RUNNER_URL" =~ https://github.com/([^/]+)$ ]]; then
  org="${BASH_REMATCH[1]}"
  token_url="$api_base/orgs/${org}/actions/runners/registration-token"
else
  echo "RUNNER_URL must be https://github.com/<org>[/<repo>]" >&2; exit 1
fi

echo "Fetching short-lived registration token..."
RUNNER_TOKEN=$(curl -fsSL -X POST \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "$token_url" | jq -r .token)

cd /actions-runner

./config.sh \
  --url "${RUNNER_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name  "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work  "${RUNNER_WORKDIR}" \
  --ephemeral \
  --unattended \
  --disableupdate

# Point docker CLI at sidecar daemon if provided
if [[ -n "${DOCKER_HOST:-}" ]]; then
  echo "Using Docker host: $DOCKER_HOST"
fi

exec ./run.sh
