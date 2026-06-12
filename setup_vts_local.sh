#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PYTHON_BIN="${PYTHON_BIN:-python3.11}"
VENV_DIR="${VENV_DIR:-.venv-vts}"
RESET_ENV="${RESET_ENV:-0}"
FORCE_INSTALL="${FORCE_INSTALL:-0}"

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Python binary not found: $PYTHON_BIN" >&2
  echo "Install Python 3.11+ or run with PYTHON_BIN=/path/to/python." >&2
  exit 1
fi

if [ "$RESET_ENV" = "1" ] && [ -d "$VENV_DIR" ]; then
  rm -rf "$VENV_DIR"
fi

if [ ! -d "$VENV_DIR" ]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

REQ_HASH="$(hash_file requirements-vts-local.txt)"
REQ_MARKER="$VENV_DIR/.requirements-vts-local.sha256"
INSTALLED_HASH=""
if [ -f "$REQ_MARKER" ]; then
  INSTALLED_HASH="$(cat "$REQ_MARKER")"
fi

if [ "$FORCE_INSTALL" = "1" ] || [ "$REQ_HASH" != "$INSTALLED_HASH" ]; then
  python -m pip install --upgrade pip setuptools wheel
  python -m pip uninstall -y torchvision >/dev/null 2>&1 || true
  python -m pip install --no-cache-dir -r requirements-vts-local.txt
  python -m pip uninstall -y torchvision >/dev/null 2>&1 || true
  printf "%s" "$REQ_HASH" > "$REQ_MARKER"
else
  echo "requirements unchanged; skipping pip install"
fi

python - <<'PY'
import sys
import torch

print("python:", sys.version.split()[0])
print("torch:", torch.__version__)
print("cuda runtime:", torch.version.cuda)

if torch.cuda.is_available():
    try:
        torch.empty(1, device="cuda")
        print("cuda: usable")
    except Exception as exc:
        print("cuda: not usable")
        print(exc)
else:
    print("cuda: unavailable")

import lightning.pytorch  # noqa: F401
print("lightning import: ok")
import local_vts_infer  # noqa: F401
print("local inference import: ok")
PY

if [ "${DOWNLOAD_CHECKPOINT:-0}" = "1" ]; then
  python local_vts_infer.py --download-only
fi

cat <<EOF

Ready.

Run:
  source $VENV_DIR/bin/activate
  python -u infer.py --input-audio ./examples/voice.wav --text "scifi cannon charging and shooting" --temperature 0.5 --model-path ./checkpoints/dynamic_v3_0415.ckpt --output-dir ./outputs --device cuda

If you want setup to download the default checkpoint, set HF_TOKEN and DOWNLOAD_CHECKPOINT:
  export HF_TOKEN=hf_...
  DOWNLOAD_CHECKPOINT=1 bash setup_vts_local.sh
EOF
