#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <remote_user@host> <local_file> <remote_final_path>" >&2
  exit 2
fi

REMOTE_TARGET="$1"
LOCAL_FILE="$2"
REMOTE_FINAL="$3"
REMOTE_TMP="/tmp/$(openssl rand -hex 16)"

if [[ ! -f "$LOCAL_FILE" ]]; then
  echo "Local file not found: $LOCAL_FILE" >&2
  exit 3
fi

scp -p "$LOCAL_FILE" "${REMOTE_TARGET}:${REMOTE_TMP}"

ssh -t "${REMOTE_TARGET}" bash -c "'
  set -euo pipefail
  DEST=\"${REMOTE_FINAL}\"
  sudo mkdir -p \$(dirname \"\$DEST\")
  sudo mv -f \"${REMOTE_TMP}\" \"\$DEST\"
  sudo chown root:root \"\$DEST\"
  sudo chmod 600 \"\$DEST\"
  echo \"Installed \$DEST\"
'"

echo "Done."
