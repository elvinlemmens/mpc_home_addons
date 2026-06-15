#!/usr/bin/env sh
set -u

# ── bootstrap: pull the pinned app code from the PRIVATE repo into /data/app ──
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

# ── run: MSG-CPP -> InfluxDB sync, once on start then every top of the hour ──
echo "[knmi] initial sync"
python3 -m data.knmi_to_influx || echo "[knmi] initial sync failed"
while true; do
  now=$(date +%s)
  next_hour=$(( (now / 3600 + 1) * 3600 ))
  sleep $(( next_hour - now ))
  echo "[knmi] hourly sync"
  python3 -m data.knmi_to_influx || echo "[knmi] sync failed; will retry next hour"
done
