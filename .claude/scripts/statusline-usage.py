#!/usr/bin/env python3
"""Pattern 4: Fine-grained progress bar with true color gradient
Combines Claude Code stdin JSON (model, context_window) with OAuth API (rate limits).
"""
import json, os, platform, subprocess, sys, time

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    data = {}

BLOCKS = ' \u258f\u258e\u258d\u258c\u258b\u258a\u2589\u2588'
R = '\033[0m'
DIM = '\033[2m'

CACHE_FILE = '/tmp/claude-usage-cache.json'
CACHE_TTL = 360


def fetch_rate_limits():
    cached = _read_cache()
    if cached is not None:
        return cached

    fresh = _fetch_from_api()
    if fresh is not None:
        with open(CACHE_FILE, 'w') as f:
            json.dump(fresh, f)
        return fresh
    return None


def _read_cache():
    try:
        mtime = os.path.getmtime(CACHE_FILE)
        if time.time() - mtime < CACHE_TTL:
            with open(CACHE_FILE) as f:
                return json.load(f)
    except (OSError, json.JSONDecodeError):
        pass
    return None


def _fetch_from_api():
    try:
        if platform.system() == 'Darwin':
            creds_raw = subprocess.run(
                ['security', 'find-generic-password', '-s', 'Claude Code-credentials', '-w'],
                capture_output=True, text=True, timeout=5
            ).stdout.strip()
        else:
            creds_path = os.path.expanduser('~/.claude/.credentials.json')
            with open(creds_path) as f:
                creds_raw = f.read()

        if not creds_raw:
            return None

        creds = json.loads(creds_raw)
        token = creds.get('claudeAiOauth', {}).get('accessToken')
        if not token:
            return None

        result = subprocess.run(
            ['curl', '-sf', '--max-time', '5',
             '-H', f'Authorization: Bearer {token}',
             '-H', 'anthropic-beta: oauth-2025-04-20',
             'https://api.anthropic.com/api/oauth/usage'],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0 or not result.stdout.strip():
            return None

        return json.loads(result.stdout)
    except Exception:
        return None


def gradient(pct):
    if pct < 50:
        r = int(pct * 5.1)
        return f'\033[38;2;{r};200;80m'
    else:
        g = int(200 - (pct - 50) * 4)
        return f'\033[38;2;255;{max(g, 0)};60m'


def bar(pct, width=10):
    pct = min(max(pct, 0), 100)
    filled = pct * width / 100
    full = int(filled)
    frac = int((filled - full) * 8)
    b = '\u2588' * full
    if full < width:
        b += BLOCKS[frac]
        b += '\u2591' * (width - full - 1)
    return b


def fmt(label, pct):
    p = round(pct)
    return f'{label} {gradient(pct)}{bar(pct)} {p}%{R}'


model = data.get('model', {}).get('display_name', 'Claude')
parts = [model]

ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    parts.append(fmt('ctx', ctx))

# rate_limits: use stdin data if available, otherwise fetch from OAuth API
rate_limits = data.get('rate_limits')
if rate_limits is None:
    usage = fetch_rate_limits()
    if usage is not None:
        five_util = usage.get('five_hour', {}).get('utilization')
        seven_util = usage.get('seven_day', {}).get('utilization')
        if five_util is not None:
            parts.append(fmt('5h', five_util))
        if seven_util is not None:
            parts.append(fmt('7d', seven_util))
else:
    five = rate_limits.get('five_hour', {}).get('used_percentage')
    if five is not None:
        parts.append(fmt('5h', five))
    week = rate_limits.get('seven_day', {}).get('used_percentage')
    if week is not None:
        parts.append(fmt('7d', week))

print(f'{DIM}|{R}'.join(f' {p} ' for p in parts), end='')
