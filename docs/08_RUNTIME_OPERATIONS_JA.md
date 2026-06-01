# 日常運用 Runbook

## 日常運用の基本方針

日常運用では、以下の観点でシステムを扱います。
- 起動と停止
- 疎通確認
- ログ確認
- 公開状態の確認
- TTS の切替や再起動
- OAuth や外部 API の健全性確認

## 起動パターン

### 開発起動
```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-up-container-sbv2.ps1
```

Google Workspace MCP や e-Stat MCP も起動したい場合:

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-up-container-sbv2.ps1 -IncludeGoogleWorkspaceMcp -IncludeEstatMcp
```

### 本番相当起動
```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

## 停止

### 開発系停止
```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-down-container-sbv2.ps1
```

### コンテナの全体停止
```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

## 疎通確認

### 1. コンテナ一覧
```powershell
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
```

### 2. フロントアプリ
- `http://localhost:3000`

### 3. injection-tool
- `http://localhost:4001/login`
- `http://localhost:4001/api/health`

### 4. TTS
```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

### 5. DBHub
- `http://localhost:8080`

## 動作確認用スクリプト

### injection 経路確認
- `test_api.ps1`
- `/api/injection/intercept/` に対して DB 連携系のテストを行う

### e-Stat 系確認
- `test_mcp.js`
- `run_requests.js`
- `validate_prompts.js`

使いどころ:
- MCP 呼び出しが本当に通っているか確認したいとき
- injectedSystemPrompt や metadata の中身を見たいとき
- デモ前に統計ドメインが生きているか確認したいとき

## ログ確認

### Docker ログ
```powershell
docker logs ark-amica --tail 200

docker logs ark-injection-tool --tail 200

docker logs ark-mcp-server --tail 200
```

optional MCP を起動している場合:

```powershell
docker logs ark-google-workspace-mcp --tail 200

docker logs ark-estat-mcp --tail 200
```

### 注目ポイント
- 401 / 403 系の認証エラー
- MCP timeout
- TTS 接続失敗
- Google OAuth callback 失敗
- JSON 設定破損によるロード失敗

## よく行う運用作業

### 1. ドメイン更新の反映
- 管理画面から保存後、フロントアプリ側で対象ドメインを再選択して確認する
- dev 環境で反映が怪しい場合は injection-tool を再起動する

### 2. dev キャッシュ破損時の復旧
- `.next` 破損や欠損 chunk が疑われる場合は対象サービスを再起動する
- 必要なら `.next` を削除後に再起動する

### 3. TTS の切替
- CPU / CUDA の切替は `.env` の `SBV2_DEVICE` を変更して行う
- 変更後は `dev-down-container-sbv2.ps1` と `dev-up-container-sbv2.ps1` で再起動する
- Piper へ切り替える場合は `AMICA_TTS_BACKEND=piper` と `AMICA_PIPER_URL=http://piper:8000` を確認し、必要な `PIPER_MODEL_URL` / `PIPER_CONFIG_URL` を設定したうえで `docker compose up -d --build --force-recreate piper amica` を使う
- 詳細手順は [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md) を参照

### 4. Cloudflare 公開の開始・停止
- 必要時だけトンネルを起動する
- URL 変更時は OAuth callback と関連設定を更新する

### 5. Amica の Ollama モデル差し替え
- 会話モデル、画像認識モデル、Piper 音声モデルの切り替え手順は [16_MODEL_SWITCH_MANUAL_JA.md](./16_MODEL_SWITCH_MANUAL_JA.md) を参照
- テキスト会話モデルを変える場合は `.env` の `AMICA_OLLAMA_MODEL` を更新する
- 画像認識モデルを変える場合は `.env` の `AMICA_VISION_OLLAMA_MODEL` を更新する
- テキスト会話と画像認識で接続先を分ける場合は `AMICA_OLLAMA_URL` と `AMICA_VISION_OLLAMA_URL` を個別に更新する
- 変更したモデルが Ollama 側で pull 済みか先に確認する
- 環境変数変更後は `docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate amica` を実行する

確認例:
```powershell
docker exec ark-amica printenv NEXT_PUBLIC_OLLAMA_MODEL NEXT_PUBLIC_VISION_OLLAMA_MODEL NEXT_PUBLIC_VISION_BACKEND NEXT_PUBLIC_HIDDEN_SETTINGS_PAGES NEXT_PUBLIC_MANAGED_CONFIG_KEYS
```

補足:
- `AMICA_MANAGED_CONFIG_KEYS` に含めた設定はブラウザ UI から変更できません
- `AMICA_HIDDEN_SETTINGS_PAGES` に `vision` や `chatbot` を含めると設定ページ自体が表示されません
- UI から変更できないのは正常動作であり、`.env` 側を更新するのが正しい運用です
- モデル切り替え時の確認順や Piper 例は [16_MODEL_SWITCH_MANUAL_JA.md](./16_MODEL_SWITCH_MANUAL_JA.md) に集約しています

### 6. Amica の設定一括管理状態を確認する
- `docker compose config` で `NEXT_PUBLIC_MANAGED_CONFIG_KEYS` と `NEXT_PUBLIC_HIDDEN_SETTINGS_PAGES` の展開結果を見る
- `docker exec ark-amica printenv` で実コンテナに渡っている値を確認する
- 設定が反映されない場合は `docker restart` ではなく `--force-recreate` で再作成する
- `docker-compose.dev.yml` などの override による上書きがないか合わせて確認する

確認例:
```powershell
docker compose config

docker exec ark-amica printenv NEXT_PUBLIC_MANAGED_CONFIG_KEYS NEXT_PUBLIC_HIDDEN_SETTINGS_PAGES NEXT_PUBLIC_VISION_BACKEND NEXT_PUBLIC_VISION_OLLAMA_URL NEXT_PUBLIC_VISION_OLLAMA_MODEL
```

## 運用時の推奨チェックリスト

毎日または公開前に確認する項目:
- `docker ps` が期待どおりか
- フロントアプリのトップ画面が開くか
- 管理画面へ入れるか
- 対象ドメインで会話できるか
- TTS が動くか
- 利用中の MCP が動くか
- 公開 URL が意図した入口だけになっているか

## 関連資料

- 管理操作: [07_ADMIN_AND_OPERATOR_MANUAL_JA.md](./07_ADMIN_AND_OPERATOR_MANUAL_JA.md)
- 障害対応: [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- 構築手順: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
