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

FAILURES=()

# Check Docker containers
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

if [ ${#FAILURES[@]} -eq 0 ]; then
  if [ "$JSON" = true ]; then
    echo '{"healthy":true,"failures":[]}'
  else
    echo "All services healthy"
  fi
  exit 0
else
  FAIL_MSG=$(printf '%s\n' "${FAILURES[@]}")

  if [ "$JSON" = true ]; then
    # Escape for JSON
    FAIL_JSON=$(printf '%s\\n' "${FAILURES[@]}" | sed 's/"/\\"/g')
    echo "{\"healthy\":false,\"failures\":[$(printf '\"%s\",' "${FAILURES[@]}" | sed 's/,$//')]}"
  else
    echo "Services DOWN:"
    echo "$FAIL_MSG"
  fi

  if [ "$NOTIFY" = true ]; then
    ~/.claude/scripts/pushover-notify.sh <<EOF
{"message":"Memory services DOWN:\n${FAIL_MSG}","cwd":""}
EOF
  fi

  exit 1
fi
