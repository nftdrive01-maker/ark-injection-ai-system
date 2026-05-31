# ark-injection-ai-system

English summary:

ark-injection-ai-system is a Docker Compose-based orchestration layer for Ark-i, Amica, injection-tool, MCP servers, TTS services, and supporting infrastructure. It is designed for domain-injected AI deployments that combine chat UI, knowledge injection, external tool integration, voice synthesis, and controlled public exposure.

Key points:

- Multi-domain AI system with switchable knowledge, UI, voice, and external integrations
- Includes Amica, injection-tool, MCP servers, PostgreSQL, DBHub, and TTS services
- Supports local operation, PoC environments, and Cloudflare-based external publishing
- Source modification is allowed
- Free for individual use
- Paid license required for corporate, organizational, governmental, or commercial use

License and usage terms:

- Personal use: free
- Code modification: allowed
- Corporate or commercial use: paid license required
- See [LICENSE.md](LICENSE.md) for details

Ark-i / Amica / injection-tool / MCP サーバー群をまとめて動かす、ドメイン注入型 AI システムの統合実行環境です。

このリポジトリは、会話 UI、知識注入管理、MCP 連携、音声合成、データベース、公開設定を Docker Compose ベースでまとめて起動し、PoC から業務導入までを同じ構成思想で扱えるようにするためのオーケストレーション層です。

## 主な特徴

- ドメインごとに知識、UI、音声、外部連携を切り替え可能
- Amica と injection-tool を分離した運用しやすい構成
- Google Workspace、e-Stat、DBHub などを MCP 経由で統合可能
- Piper / Style-Bert-VITS2-nftdrive などの音声合成に対応
- Cloudflare Tunnel や LAN HTTPS による外部公開に対応

## 構成サービス

| サービス | 役割 | 既定ポート |
| --- | --- | ---: |
| Amica | ユーザー向け会話 UI | 3000 |
| injection-tool | 知識注入、管理画面、公開設定 API | 4001 |
| mcp-server | 汎用 MCP ルーター/検証用サーバー | 8000 |
| google-workspace-mcp | Google Workspace 連携 | 8001 |
| estat-mcp | e-Stat 連携 | 8002 |
| SBV2 / Piper | 音声合成 | 5000 / 5001 |
| PostgreSQL | 永続データ保存 | 5432 |
| DBHub | DB ゲートウェイ | 8080 |

## クイックスタート

### 1. 前提

- Docker Desktop
- Docker Compose
- 必要に応じて Ollama または OpenAI 互換 API

### 2. 環境変数を用意

`.env.example` を `.env` にコピーし、必要な値を設定します。

```powershell
Copy-Item .env.example .env
```

最低限、以下を自分の環境に合わせて見直してください。

- `AMICA_CHATBOT_BACKEND`
- `AMICA_OLLAMA_URL`
- `AMICA_OLLAMA_MODEL`
- `INJECTION_ADMIN_USERNAME`
- `INJECTION_ADMIN_PASSWORD`
- `INJECTION_SESSION_SECRET`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`

### 3. 開発起動

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

起動後の既定 URL:

- Amica: http://localhost:3000
- injection-tool: http://localhost:4001

## 外部公開

フロントアプリの一時公開には Cloudflare Quick Tunnel を使えます。

```powershell
cloudflared tunnel --url http://localhost:3000
```

公開 URL を固定したい場合や、管理画面を安全に外部公開したい場合は Cloudflare Named Tunnel + Cloudflare Access を推奨します。

詳細:

- [EXTERNAL_PUBLISH_MANUAL_JA.md](EXTERNAL_PUBLISH_MANUAL_JA.md)
- [docs/13_CLOUDFLARE_ACCESS_SETUP_JA.md](docs/13_CLOUDFLARE_ACCESS_SETUP_JA.md)

## ドキュメント

- [docs/01_SYSTEM_OVERVIEW_JA.md](docs/01_SYSTEM_OVERVIEW_JA.md)
- [docs/05_SETUP_AND_DEPLOYMENT_JA.md](docs/05_SETUP_AND_DEPLOYMENT_JA.md)
- [docs/06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](docs/06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- [docs/README_JA.md](docs/README_JA.md)

## 関連リポジトリ

- Amica fork: https://github.com/nftdrive01-maker/amica-nftdrive
- Amica fork の既定運用ブランチ: feat-add-injection
- Style-Bert-VITS2 fork: https://github.com/nftdrive01-maker/Style-Bert-VITS2-nftdrive

このリポジトリの Compose は `../amica` のローカル checkout を bind mount するため、実際に参照される内容は GitHub の `master` ではなくローカルで checkout しているブランチです。NFTDrive 運用では `feat-add-injection` を前提にしています。

## ライセンスと利用条件

このリポジトリのコードは改変可能です。

- 個人利用は無料です
- 法人、団体、行政、商用利用は有償ライセンスの対象です
- 詳細は [LICENSE.md](LICENSE.md) を参照してください
- OSS ライセンス案内は [OPEN_SOURCE_NOTICES.md](OPEN_SOURCE_NOTICES.md) を参照してください

商用利用や導入相談は NFTDrive までお問い合わせください。

## 注意事項

- `.env`、OAuth credential、ローカル証明書、各種ログは公開リポジトリに含めないでください
- Quick Tunnel は URL が毎回変わるため、本番運用には向きません
- Google Workspace 連携を使う場合は OAuth コールバック URL の更新が必要です