#!/bin/bash
# Health check for memory infrastructure services
# Usage:
#   healthcheck.sh              - Check all services, output status
#   healthcheck.sh --notify     - Check all services, send Pushover on failure
#   healthcheck.sh --json       - Output JSON for context-injector.js
#
# Exit codes: 0 = all healthy, 1 = some services down

NOTIFY=false
JSON=false
for arg in "$@"; do
  case "$arg" in
    --notify) NOTIFY=true ;;
    --json) JSON=true ;;
  esac
done

STATE_FILE="/tmp/healthcheck-last-failure"
FAILURES=()

# Check Docker container
check_container() {
  local name="$1"
  local health
  health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null)
  if [ $? -ne 0 ]; then
    FAILURES+=("$name: not running")
    return 1
  elif [ "$health" != "healthy" ] && [ "$health" != "" ]; then
    FAILURES+=("$name: $health")
    return 1
  fi
  return 0
}

# Check HTTP endpoint
check_http() {
  local name="$1"
  local url="$2"
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)
  if [ "$status" -lt 200 ] || [ "$status" -ge 500 ] 2>/dev/null; then
    FAILURES+=("$name: HTTP $status")
    return 1
  fi
  return 0
}

# Check HTTP endpoint with Cloudflare Access headers (via envchain)
check_http_cf() {
  local name="$1"
  local url="$2"
  local status
  status=$(envchain ollama-api bash -c 'curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -H "CF-Access-Client-Id: $ACCESS_CLIENT_ID" -H "CF-Access-Client-Secret: $ACCESS_CLIENT_SECRET" "'"$url"'"' 2>/dev/null)
  if [ "$status" -lt 200 ] || [ "$status" -ge 500 ] 2>/dev/null; then
    FAILURES+=("$name: HTTP $status")
    return 1
  fi
  return 0
}

# Check TCP port
check_port() {
  local name="$1"
  local port="$2"
  if ! nc -z -w 3 localhost "$port" 2>/dev/null; then
    FAILURES+=("$name: port $port unreachable")
    return 1
  fi
  return 0
}

# Run checks
check_container "memory-postgres"
check_container "memory-falkordb"
check_port "PostgreSQL" 15432
check_port "FalkorDB" 16379
check_http "Graphiti API" "http://localhost:8003/"
check_http "Ollama (local)" "http://localhost:11434/"

# Check remote Ollama via Cloudflare Access (if envchain is available)
REMOTE_OLLAMA_URL=$(envchain ollama-api bash -c 'echo $OLLAMA_API_ENDPOINT' 2>/dev/null)
if [ -n "$REMOTE_OLLAMA_URL" ]; then
  check_http_cf "Ollama (remote)" "$REMOTE_OLLAMA_URL/"
fi

if [ ${#FAILURES[@]} -eq 0 ]; then
  # All healthy - clear state file if it exists
  [ -f "$STATE_FILE" ] && rm -f "$STATE_FILE"

  if [ "$JSON" = true ]; then
    echo '{"healthy":true,"failures":[]}'
  else
    echo "All services healthy"
  fi
  exit 0
else
  FAIL_MSG=$(printf '%s\n' "${FAILURES[@]}")
  FAIL_HASH=$(echo "$FAIL_MSG" | shasum | cut -c1-8)

  if [ "$JSON" = true ]; then
    echo "{\"healthy\":false,\"failures\":[$(printf '\"%s\",' "${FAILURES[@]}" | sed 's/,$//')]}"
  else
    echo "Services DOWN:"
    echo "$FAIL_MSG"
  fi

  if [ "$NOTIFY" = true ]; then
    LAST_HASH=""
    [ -f "$STATE_FILE" ] && LAST_HASH=$(cat "$STATE_FILE")

    # Only notify if failure state changed (avoid repeated notifications)
    if [ "$FAIL_HASH" != "$LAST_HASH" ]; then
      echo "$FAIL_HASH" > "$STATE_FILE"
      ~/.claude/scripts/pushover-notify.sh <<EOF
{"message":"Memory services DOWN:\n${FAIL_MSG}","cwd":""}
EOF
    fi
  fi

  exit 1
fi
