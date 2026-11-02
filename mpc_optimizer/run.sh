#!/usr/bin/env bash
set -uo pipefail

# ── bootstrap: pull the pinned app code from the PRIVATE repo into /data/app ──
# Token is used only for the clone, then stripped from .git/config. On any git
# failure we fall back to the last-good checkout so a GitHub outage at start
# does not brick the add-on.
APP=/data/app
OPTS=/data/options.json
opt() { python3 -c "import json;print(json.load(open('$OPTS')).get('$1',''))" 2>/dev/null || true; }

REPO=$(opt GITHUB_REPO); REF=$(opt GIT_REF); TOKEN=$(opt GITHUB_TOKEN)
if [ -z "$REPO" ] || [ -z "$REF" ]; then
  echo "[bootstrap] set GITHUB_REPO and GIT_REF in the add-on options" >&2
  exit 1
fi
URL="https://github.com/$REPO.git"
if [ -n "$TOKEN" ]; then CLONE_URL="https://x-access-token:$TOKEN@github.com/$REPO.git"; else CLONE_URL="$URL"; fi

echo "[bootstrap] fetching $REPO @ $REF"
rm -rf /data/app_new
if git clone --depth 1 --branch "$REF" "$CLONE_URL" /data/app_new 2>/tmp/giterr; then
  git -C /data/app_new remote set-url origin "$URL"   # drop the token from .git/config
  rm -rf "$APP"; mv /data/app_new "$APP"
  echo "[bootstrap] updated to $REF"
else
  echo "[bootstrap] git clone failed:" >&2; cat /tmp/giterr >&2; rm -rf /data/app_new
  if [ -d "$APP" ]; then
    echo "[bootstrap] using last-good checkout in $APP" >&2
  else
    echo "[bootstrap] no cached checkout available; aborting" >&2; exit 1
  fi
fi
cd "$APP" || exit 1
export PYTHONPATH="$APP"

# ── dependencies: install whatever the fetched code needs and the image lacks ─
# The code is pulled at start, but libraries are baked into the image at build
# time, so a new dependency used to fail with "No module named ..." until the
# add-on image was rebuilt. pip only installs what is missing (a few seconds
# when everything is present). A failure (offline, build error) is logged and
# the add-on starts anyway with what it has.
if [ -f "$APP/requirements.txt" ]; then
  echo "[bootstrap] checking python dependencies (requirements.txt)"
  pip install --no-cache-dir --disable-pip-version-check -q -r "$APP/requirements.txt" \
    || echo "[bootstrap] WARNING: dependency install failed; continuing with installed packages" >&2
fi

# ── run: optimizer (15-min loop) + dashboard, each restarted on crash ────────
supervise () {
    local name="$1"; shift
    while true; do
        echo "[mpc] starting ${name}"
        "$@"
        echo "[mpc] ${name} exited (code $?); restarting in 15s"
        sleep 15
    done
}

supervise dashboard python3 dashboard/server.py --host 0.0.0.0 --port 8080 &
supervise optimizer python3 run_optimizer.py &
wait
