#!/bin/sh
set -eu

apk add --no-cache iptables iproute2 bind-tools >/dev/null

# Wait for dind DNS and get its IP
echo "[redirect] waiting for dind DNS..."
for i in $(seq 1 60); do
  if DIND_IP=$(getent hosts dind | awk '{print $1}'); then
    [ -n "$DIND_IP" ] && break
  fi
  sleep 1
done
if [ -z "${DIND_IP:-}" ]; then
  echo "[redirect] ERROR: could not resolve 'dind' after 60s" >&2
  exit 1
fi
echo "[redirect] dind IP = $DIND_IP"

# Create a dedicated chain (if not exists) so rules are tidy & idempotent
CHAIN="REDIR_LOCALHOST"
# shellcheck disable=SC2015
iptables -t nat -L $CHAIN >/dev/null 2>&1 || iptables -t nat -N $CHAIN

# Ensure OUTPUT for 127.0.0.1 jumps to our chain exactly once
if ! iptables -t nat -C OUTPUT -p tcp -d 127.0.0.1 -j $CHAIN 2>/dev/null; then
  iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 -j $CHAIN
fi

# Idempotent helper: add a rule if it isn't there yet
add_rule() {
  # $1...$n = rule args after '-A CHAIN'
  if ! iptables -t nat -C "$CHAIN" "$@" 2>/dev/null; then
    iptables -t nat -A "$CHAIN" "$@"
  fi
}

# Exclusions: keep some ports truly local to the runner
add_rule -p tcp --dport 2375 -j RETURN   # example: docker TCP if you bind it locally
add_rule -p tcp --dport 22   -j RETURN   # example: SSH within runner

# Catch-all: any other localhost TCP → DNAT to dind at same port
# We match all TCP to 127.0.0.1 and DNAT to dind; the original dest port is preserved.
add_rule -p tcp -j DNAT --to-destination "$DIND_IP"

echo "[redirect] rules applied:"
iptables -t nat -S OUTPUT | sed -n '1,200p' | sed -n "/-N $CHAIN/,\$p"

# Stay alive
tail -f /dev/null
