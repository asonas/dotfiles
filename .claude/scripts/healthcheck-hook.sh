#!/bin/bash
# UserPromptSubmit hook: check memory services health
# Outputs JSON warning message if any service is down
# Runs quickly (< 5s) so it doesn't block prompt processing

RESULT=$(~/.claude/scripts/healthcheck.sh --json 2>/dev/null)

HEALTHY=$(echo "$RESULT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('healthy', True))" 2>/dev/null)

if [ "$HEALTHY" = "False" ]; then
  FAILURES=$(echo "$RESULT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for f in data.get('failures', []):
    print(f'- {f}')
" 2>/dev/null)

  cat <<EOF
{"message":"\n---\n**[WARNING: Memory Services Down]**\n\n以下のサービスが停止しています。store_memory/graphiti_add_episodeが失敗する可能性があります。\n\n${FAILURES}\n---\n"}
EOF
fi
