# トラブルシューティング

## 使い方

この資料は、症状から原因候補と確認手順を引くための runbook です。まず影響範囲を切り分け、次に対象サービスを絞ってください。

## 症状別一覧

| 症状 | 主な原因候補 | 最初に確認すること |
|---|---|---|
| フロントアプリが開かない | amica 未起動、ポート競合、compose 未起動 | `docker ps`、`http://localhost:3000` |
| 管理画面に入れない | injection-tool 未起動、認証失敗、dev 破損 | `http://localhost:4001/login`、コンテナログ |
| TTS が動かない | TTS 未起動、接続先違い、SBV2 初期化失敗 | `http://127.0.0.1:5000/docs`、環境変数 |
| 画像認識が動かない | Vision backend 不一致、画像対応モデル未導入、Vision Ollama URL 不達 | `.env` の Vision 設定、amica ログ |
| MCP が使われない | domain 設定ミス、MCP URL 不達、ルール未一致 | admin の MCP 設定、`test_mcp.js` |
| e-Stat が動かない | `ESTAT_APP_ID` 未設定、ドメイン違い | `.env`、`domainId=e-stat_mcp` |
| Google 認証に失敗する | OAuth callback 不一致、外部 URL 未反映 | `CLOUDFLARE_EXTERNAL_URL`、GCP 設定 |
| Cloudflare URL で開けない | cloudflared 未起動、フロントアプリ未起動 | トンネル状態、`localhost:3000` |
| DBHub に接続できない | database 未起動、認証情報不一致 | `docker ps`、DB 環境変数 |
| 設定変更が反映されない | dev ホットリロード不整合、managed config、コンテナ再作成不足 | `.env`、service 再作成 |

## 個別対応

### 1. フロントアプリが開かない
確認:
```powershell
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
```

対処:
- `ark-amica` が起動していないなら起動する
- ポート 3000 が別プロセスに使われていないか確認する
- dev 起動なら `dev-up-container-sbv2.ps1` を再実行する

### 2. injection-tool の login が壊れた
症状:
- `/login` が白画面
- chunk 読み込みエラー
- 500 エラー

対処:
- 対象コンテナを再起動する
- 必要なら `.next` を削除して再起動する
- Docker ボリューム開発では hot reload が崩れることがある

### 3. TTS が使えない
確認:
```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

対処:
- `ark-sbv2-init` と `ark-sbv2` が起動しているか確認する
- `docker logs ark-sbv2-init --tail 200` と `docker logs ark-sbv2 --tail 200` を確認する
- `SBV2_DEVICE` が意図した値か確認する

### 4. MCP が使われない
確認:
- 管理画面の MCP タブで対象サーバーが有効か
- URL が Docker から見える URL か
- ルールや allowed tools が正しいか
- ドメインに mcpServerIds が紐付いているか

補足:
- Docker 内から `localhost` は自身を指すため、ホスト URL をそのまま使うと失敗する場合がある
- e-Stat 検証では domainId が `e-stat_mcp` である必要がある

### 5. 画像認識が動かない
確認:
- `.env` の `AMICA_VISION_BACKEND` が意図した値か
- `AMICA_VISION_OLLAMA_URL` が Docker から到達できる URL か
- `AMICA_VISION_OLLAMA_MODEL` が Ollama 側に pull 済みか
- 画像対応モデルを使っているか
- `ark-amica` のログに Ollama proxy error が出ていないか

対処:
- Ollama で使うなら `AMICA_VISION_BACKEND=vision_ollama` にする
- テキスト会話と同じ Ollama を使うなら `AMICA_VISION_OLLAMA_URL` を `AMICA_OLLAMA_URL` と揃える
- Vision 専用サーバーに分ける場合は `AMICA_VISION_OLLAMA_URL` だけを別ホストに向ける
- `llava` など画像入力対応モデルを事前に pull する
- `.env` を変えた後は `docker compose up -d --force-recreate amica` を実行する
- ブラウザ設定から変更できない場合は `AMICA_MANAGED_CONFIG_KEYS` による中央管理が有効になっているか確認する

### 6. Google OAuth callback エラー
確認:
- `CLOUDFLARE_EXTERNAL_URL`
- Google Cloud Console の承認済みリダイレクト URI
- `google-workspace-mcp` の外部 URL 設定

対処:
- 現在の公開 URL に合わせて callback を更新する
- URL 変更後は関連コンテナを再作成する

### 7. Cloudflare Tunnel が開かない
確認:
- `cloudflared tunnel --url http://localhost:3000` が稼働しているか
- `localhost:3000` が正常に開くか
- admin の tunnel status に URL が出ているか

### 8. DBHub 接続失敗
確認:
- `ark-database` の healthcheck が通っているか
- `DB_USER`, `DB_PASSWORD`, `DB_NAME` が一致しているか
- DBHub の DSN が compose 定義と一致しているか

### 9. 設定変更が反映されない
確認:
- `.env` を変更しただけで `docker restart` しかしていないか
- `AMICA_MANAGED_CONFIG_KEYS` に対象キーが含まれているか
- `AMICA_HIDDEN_SETTINGS_PAGES` により設定画面自体を隠していないか
- 変更対象が amica なのか injection-tool なのかを切り分けられているか

対処:
- 環境変数変更後は `docker compose up -d --force-recreate amica` を実行する
- `docker-compose.dev.yml` などの override が `.env` の値を上書きしていないか確認する
- managed config の対象なら、ブラウザ localStorage ではなく `.env` 側を修正する
- 反映確認は `docker compose config` と対象コンテナの環境変数で行う

### 10. 設定 JSON が壊れた
症状:
- 管理画面で MCP や設定が消えたように見える

対処:
- `data/mcp-servers.json` や関連 JSON の構文を確認する
- JSON 破損時は空配列扱いに見えることがある

## 便利な確認コマンド

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

docker logs ark-injection-tool --tail 200

docker logs ark-amica --tail 200

docker logs ark-google-workspace-mcp --tail 200

docker logs ark-estat-mcp --tail 200

Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

## 切り分け順序

1. 入口のフロントアプリが正常か
2. injection-tool が正常か
3. TTS / MCP / OAuth のどの下流が失敗しているか
4. そのサービス単体で疎通できるか
5. 設定値や URL が current 環境と一致しているか

## 関連資料

- 日常運用: [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- 構築: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- セキュリティ: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
