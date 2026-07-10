#!/usr/bin/env python3
"""Pattern 4: Fine-grained progress bar with true color gradient
Combines Claude Code stdin JSON (model, context_window) with OAuth API (rate limits).
"""
import json, os, platform, subprocess, sys, time
from datetime import datetime

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
        _write_cache(fresh)
        return fresh
    return None


def _write_cache(payload):
    try:
        with open(CACHE_FILE, 'w') as f:
            json.dump(payload, f)
    except OSError:
        pass


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


def fmt_reset(value):
    if not value:
        return ''
    try:
        if isinstance(value, (int, float)):
            dt = datetime.fromtimestamp(value).astimezone()
        else:
            dt = datetime.fromisoformat(value).astimezone()
        now = datetime.now().astimezone()
        if dt.date() == now.date():
            label = dt.strftime('%H:%M')
        else:
            label = dt.strftime('%m/%d %H:%M')
        return f' {DIM}\u21bb{label}{R}'
    except Exception:
        return ''


def get_dir_and_branch(cwd):
    home = os.path.expanduser('~')
    display = cwd.replace(home, '~', 1) if cwd.startswith(home) else cwd
    try:
        branch = subprocess.run(
            ['git', '-C', cwd, 'rev-parse', '--abbrev-ref', 'HEAD'],
            capture_output=True, text=True, timeout=3
        ).stdout.strip()
    except Exception:
        branch = ''
    return f'{display} [{branch}]' if branch else display


cwd = data.get('cwd', '')

# Line 1: directory and branch
line1_parts = []
if cwd:
    line1_parts.append(get_dir_and_branch(cwd))

# Line 2: model, context, rate limits
line2_parts = []

model = data.get('model', {}).get('display_name', 'Claude')
line2_parts.append(model)

ctx = data.get('context_window', {}).get('used_percentage')
if ctx is not None:
    line2_parts.append(fmt('ctx', ctx))

# rate_limits: use stdin data if available, otherwise fetch from OAuth API
rate_limits = data.get('rate_limits')
if rate_limits is None:
    usage = fetch_rate_limits()
    if usage is not None:
        five = usage.get('five_hour') or {}
        seven = usage.get('seven_day') or {}
        if five.get('utilization') is not None:
            line2_parts.append(fmt('5h', five['utilization']) + fmt_reset(five.get('resets_at')))
        if seven.get('utilization') is not None:
            line2_parts.append(fmt('7d', seven['utilization']) + fmt_reset(seven.get('resets_at')))
else:
    five = rate_limits.get('five_hour') or {}
    week = rate_limits.get('seven_day') or {}
    # Cache in OAuth API format (utilization) so the fallback path can read it
    _write_cache({
        'five_hour': {'utilization': five.get('used_percentage'), 'resets_at': five.get('resets_at')},
        'seven_day': {'utilization': week.get('used_percentage'), 'resets_at': week.get('resets_at')},
    })
    if five.get('used_percentage') is not None:
        line2_parts.append(fmt('5h', five['used_percentage']) + fmt_reset(five.get('resets_at')))
    if week.get('used_percentage') is not None:
        line2_parts.append(fmt('7d', week['used_percentage']) + fmt_reset(week.get('resets_at')))

lines = []
if line1_parts:
    lines.append(f'{DIM}|{R}'.join(f' {p} ' for p in line1_parts))
if line2_parts:
    lines.append(f'{DIM}|{R}'.join(f' {p} ' for p in line2_parts))

print('\n'.join(lines), end='')
