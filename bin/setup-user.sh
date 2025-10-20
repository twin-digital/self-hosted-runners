#!/usr/bin/env bash
set -euo pipefail

USERNAME="gha-runners"
HOME_DIR="/home/${USERNAME}"
REPO_URL="https://github.com/twin-digital/self-hosted-runners.git"
REPO_DIR="${HOME_DIR}/self-hosted-runners"

# --- helpers ---
user_exists() { getent passwd "${USERNAME}" >/dev/null 2>&1; }
in_group() { id -nG "${USERNAME}" 2>/dev/null | tr ' ' '\n' | grep -qx "${1}"; }

# --- create user if missing ---
if ! user_exists; then
  echo "[info] creating user ${USERNAME}"
  sudo adduser \
    --shell /usr/sbin/nologin \
    --gecos "GitHub Actions Runner,,,," \
    --disabled-password \
    "${USERNAME}"
else
  echo "[info] user ${USERNAME} already exists; skipping creation"
fi

# --- ensure docker group membership ---
if ! in_group docker; then
  echo "[info] adding ${USERNAME} to docker group"
  sudo usermod -aG docker "${USERNAME}"
else
  echo "[info] ${USERNAME} already in docker group"
fi

# --- lock password (idempotent) ---
if ! sudo passwd -S "${USERNAME}" | grep -q ' L '; then
  echo "[info] locking password for ${USERNAME}"
  sudo passwd -l "${USERNAME}"
else
  echo "[info] password already locked for ${USERNAME}"
fi

# --- ensure home directory ownership (create if missing just in case) ---
if [ ! -d "${HOME_DIR}" ]; then
  echo "[info] creating home dir ${HOME_DIR}"
  sudo mkdir -p "${HOME_DIR}"
fi
sudo chown -R "${USERNAME}:${USERNAME}" "${HOME_DIR}"

# --- clone or update repo as the runner user ---
if [ -d "${REPO_DIR}/.git" ]; then
  echo "[info] repo exists; updating with pull --rebase"
  sudo -u "${USERNAME}" bash -lc "
    cd '${REPO_DIR}' && \
    git fetch --all --prune && \
    git pull --rebase --autostash --stat
  "
else
  echo "[info] cloning repo to ${REPO_DIR}"
  sudo -u "${USERNAME}" bash -lc "
    cd '${HOME_DIR}' && \
    git clone '${REPO_URL}'
  "
fi

echo "[done] setup complete"
