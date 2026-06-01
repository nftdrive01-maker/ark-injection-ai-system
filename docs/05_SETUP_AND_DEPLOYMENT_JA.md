# セットアップとデプロイ

最短導入手順は [15_INSTALLATION_MANUAL_JA.md](./15_INSTALLATION_MANUAL_JA.md) を先に参照してください。

## 前提ソフト

推奨環境:
- Windows
- Docker Desktop
- PowerShell
- Node.js と npm
- cloudflared を使う場合は cloudflared
- LAN HTTPS を使う場合は mkcert
- Google Workspace を使う場合は Google OAuth クレデンシャル
- e-Stat を使う場合は ESTAT_APP_ID

## リポジトリ配置前提

このワークスペースでは以下のように並列配置される前提です。

- ark-injection-ai-system
- amica  （amica-nftdrive のローカル配置先）
- injection-tool
- mcp-server
- google-workspace-mcp
- estat-mcp
- sbv2/Style-Bert-VITS2  （Style-Bert-VITS2-nftdrive のローカル配置先）

compose からは `../amica`（amica-nftdrive のローカル配置先）や `../injection-tool` などを参照するため、相対配置を崩さないでください。

## 初回設定

1. `ark-injection-ai-system/.env.example` を参考に `.env` を作成する
2. 必要に応じて以下を設定する
   - `AMICA_OLLAMA_URL`
   - `AMICA_OLLAMA_MODEL`
   - `AMICA_VISION_BACKEND`
   - `AMICA_VISION_OLLAMA_URL`
   - `AMICA_VISION_OLLAMA_MODEL`
   - `AMICA_MANAGED_CONFIG_KEYS`
   - `AMICA_HIDDEN_SETTINGS_PAGES`
   - `AMICA_OPENAI_APIKEY`
   - `GOOGLE_OAUTH_CLIENT_ID`
   - `GOOGLE_OAUTH_CLIENT_SECRET`
   - `ESTAT_APP_ID`
   - `DB_USER`
   - `DB_PASSWORD`
   - `DB_NAME`
3. 公開運用をする場合は `CLOUDFLARE_EXTERNAL_URL` を後から設定する

GitHub 管理外で別途用意が必要なもの:

- `.env` に設定する秘密情報
   - Google OAuth client ID / secret
   - injection-tool 管理者アカウント
   - OpenAI などの API キー
   - `ESTAT_APP_ID`
- `ark-injection-ai-system/google-workspace-mcp-credentials` に保存する Google Workspace の credential / token
- `../sbv2/Style-Bert-VITS2/model_assets` と `../sbv2/Style-Bert-VITS2/bert`
- `../piper/data` に保持される Piper モデル

コードは GitHub から取得できますが、上記は機密情報または大型モデル資産のため、別の配布経路か手動配置を前提にしてください。

Amica を中央集権的に運用する場合の基本方針:

- テキスト会話は `AMICA_OLLAMA_URL` と `AMICA_OLLAMA_MODEL` で固定する
- 画像認識は `AMICA_VISION_BACKEND=vision_ollama` を基準にし、必要なら `AMICA_VISION_OLLAMA_URL` と `AMICA_VISION_OLLAMA_MODEL` を指定する
- ユーザーに設定変更を許可しない場合は `AMICA_MANAGED_CONFIG_KEYS` に backend / URL / model を含める
- 設定メニュー自体を見せたくない場合は `AMICA_HIDDEN_SETTINGS_PAGES=vision,developer` のように指定する
- `.env` を変更した後は `docker restart` ではなく `docker compose up -d --force-recreate amica` を使う

## 開発起動

開発起動は以下を基準とします。

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-up-container-sbv2.ps1 -Build
```

このスクリプトは以下の compose を使用します。
- `docker-compose.yml`
- `docker-compose.dev.yml`

起動対象:
- amica  （amica-nftdrive のローカル配置先）
- injection-tool
- mcp-server
- sbv2

特徴:
- フロントアプリと injection-tool は Node.js 開発サーバー
- bind mount によりソース反映を行う
- polling を有効化して Windows + Docker 開発でも変更検知しやすくしている
- `sbv2-init` が初回に BERT とデフォルト推論モデルを準備する

## SBV2 の CPU / CUDA 切替

SBV2 は常に Compose サービスとして起動します。切替は `.env` の `SBV2_DEVICE` で行います。

例:

```env
SBV2_DEVICE=cpu
```

```env
SBV2_DEVICE=cuda
```

変更後は再起動します。

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1 -Build
```

GPU を使う場合は、Docker が GPU を利用できる構成であることを事前に確認してください。

## 本番相当起動

本番相当のコンテナ build ベース起動は以下を使います。

```powershell
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build
```

注意:
- `docker-compose.yml` 単体では build 定義が足りないため、本番相当では `docker-compose.prod.yml` の併用が必要です
- injection-tool の data ディレクトリは volume で保持されます

## LAN HTTPS 起動

LAN 内の HTTPS 公開では、先に証明書を作成し、その後 Caddy を追加起動します。

```powershell
cd D:\ark-injection-ai-system
.\scripts\setup-lan-https.ps1

docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.lan-https.yml up -d amica-https
```

## Cloudflare Tunnel 公開

Cloudflare を使う場合の概要手順:

1. 開発または本番相当のフロントアプリを起動する
2. `cloudflared tunnel --url http://localhost:3000` を実行する
3. 表示された URL を `.env` の `CLOUDFLARE_EXTERNAL_URL` に設定する
4. `injection-tool` と `google-workspace-mcp` を再作成する

例:

```powershell
cloudflared tunnel --url http://localhost:3000
```

詳細は `EXTERNAL_PUBLISH_MANUAL_JA.md` を参照してください。

## Google Workspace の有効化

最低限必要なこと:
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`
- リダイレクト URI の整備
- `google-workspace-mcp-credentials` ディレクトリの永続化

この `google-workspace-mcp-credentials` は GitHub に含めず、環境ごとに安全な方法で配布・保管してください。

Cloudflare 経由で公開する場合は callback URL も外部 URL に合わせて更新してください。

## e-Stat の有効化

`.env` に以下を設定します。

```env
ESTAT_APP_ID=your_app_id
```

起動後、`estat-mcp` は `estat-mcp serve --transport sse --host 0.0.0.0 --port 8000` として動作します。

## 音声モデル資産

SBV2 は `../sbv2/Style-Bert-VITS2/model_assets` と `../sbv2/Style-Bert-VITS2/bert` を参照します。これらは GitHub だけでは揃わないため、初回セットアップ時にモデル取得または手動配置が必要です。

Piper は `../piper/data` をモデル保存先として使い、初回起動時に `.env` の `PIPER_MODEL_URL` と `PIPER_CONFIG_URL` から取得します。ネットワーク制限がある環境では、事前配置かミラー URL の用意を検討してください。

## 起動確認

### Docker コンテナ確認

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
```

### フロントアプリ確認
- `http://localhost:3000`

### injection-tool 確認
- `http://localhost:4001`
- `http://localhost:4001/login`

### TTS 確認
- `http://127.0.0.1:5000/docs` またはコンテナ構成に応じた URL

### DBHub 確認
- `http://localhost:8080`

## 停止

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-down-container-sbv2.ps1
```

## 関連資料

- セキュリティと公開: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- 運用 runbook: [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- 障害対応: [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- 設定一覧: [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- Piper 手順: [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md)
