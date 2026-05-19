# statusline-usage.py: macOSでの認証情報の取得方法

`~/.claude/scripts/statusline-usage.py` がレートリミット (5h / 7d) を Anthropic の OAuth API から取得する際、macOS では Keychain から OAuth アクセストークンを取り出している。その仕組みをまとめる。

## 概要

Claude Code は OAuth 認証情報を macOS の Keychain に `Claude Code-credentials` というサービス名の generic password として保存している。statusline-usage.py はこれを `security` コマンドで取り出し、Bearer トークンとして `https://api.anthropic.com/api/oauth/usage` に投げる。

## コード

該当箇所は `statusline-usage.py` の `_fetch_from_api()` (48〜80行目) にある。macOS 分岐の本質は次の3行。

```python
creds_raw = subprocess.run(
    ['security', 'find-generic-password', '-s', 'Claude Code-credentials', '-w'],
    capture_output=True, text=True, timeout=5
).stdout.strip()
```

- `security find-generic-password` は macOS の Keychain に登録された generic password を検索するコマンド
- `-s 'Claude Code-credentials'` でサービス名 (kSecAttrService) による絞り込み
- `-w` は "password だけを stdout に出力" するオプション。これがないと属性情報も一緒に出てしまい、JSON としてパースできない
- `timeout=5` で Keychain アクセスが応答しないケースに備える

## 取得した文字列の構造

Keychain から返ってくる文字列は JSON で、以下の構造を持つ。

```json
{
  "claudeAiOauth": {
    "accessToken": "...",
    "refreshToken": "...",
    "expiresAt": 1234567890
  }
}
```

statusline-usage.py が利用するのは `claudeAiOauth.accessToken` のみ。

```python
creds = json.loads(creds_raw)
token = creds.get('claudeAiOauth', {}).get('accessToken')
```

## 取得後の利用

得られたトークンを Bearer 認証で OAuth API に投げる。

```python
result = subprocess.run(
    ['curl', '-sf', '--max-time', '5',
     '-H', f'Authorization: Bearer {token}',
     '-H', 'anthropic-beta: oauth-2025-04-20',
     'https://api.anthropic.com/api/oauth/usage'],
    capture_output=True, text=True, timeout=10
)
```

レスポンスには `five_hour.utilization` と `seven_day.utilization`、それぞれの `resets_at` (ISO8601) が含まれる。

## キャッシュ

statusLine は頻繁に呼び出されるため、API レスポンスを `/tmp/claude-usage-cache.json` に保存し、TTL 360秒で再利用する (statusline-usage.py:20-45)。Keychain アクセス自体も API 呼び出しも、キャッシュが有効な間はスキップされる。

## 初回アクセスのダイアログ

`security` コマンドが Keychain にアクセスする際、macOS が許可ダイアログを表示することがある。`Claude Code` というアプリケーション名で署名された Keychain 項目にコマンドラインから触ろうとするため、初回は「許可」か「常に許可」を選ぶ必要がある。"常に許可" を選んでおくと以降は無音で取得できる。

## エラー時の挙動

`_fetch_from_api()` は `try ... except Exception: return None` で全例外を握りつぶす設計になっている (statusline-usage.py:79-80)。具体的には次のいずれかで `None` が返る。

- `security` コマンドの timeout や非ゼロ終了
- Keychain 項目が存在しない (空文字列)
- JSON パース失敗
- `accessToken` が見つからない
- curl の失敗 (`returncode != 0` や空レスポンス)

`None` が返るとレートリミット行は表示されず、status bar は `cwd / model / ctx` のみの最小表示にフォールバックする。エラーメッセージは一切出ないため、status bar が突然レートリミットを表示しなくなったときは Keychain と API を手で叩いて切り分けるのがよい。

## 手動確認コマンド

```bash
# Keychain から生の認証情報を取り出す
security find-generic-password -s 'Claude Code-credentials' -w

# accessToken だけ取り出す
security find-generic-password -s 'Claude Code-credentials' -w | jq -r '.claudeAiOauth.accessToken'

# OAuth API を直接叩く
TOKEN=$(security find-generic-password -s 'Claude Code-credentials' -w | jq -r '.claudeAiOauth.accessToken')
curl -sf -H "Authorization: Bearer $TOKEN" \
     -H 'anthropic-beta: oauth-2025-04-20' \
     https://api.anthropic.com/api/oauth/usage | jq .
```

## Linux との対比

Linux など macOS 以外の環境では Keychain がないため、Claude Code は同じ JSON を `~/.claude/.credentials.json` に平文で保存する。statusline-usage.py もそちらを直接読みに行く (statusline-usage.py:55-58)。macOS で Keychain を使うのは、平文保存を避けて OS の鍵管理に乗せるためである。
