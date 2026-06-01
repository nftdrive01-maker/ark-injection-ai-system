# 技術仕様

## システム境界

ark-injection-ai-system は以下の層に分かれます。

1. プレゼンテーション層
- フロントアプリ

2. 知識注入・管理層
- injection-tool

3. 外部データ接続層
- mcp-server
- google-workspace-mcp (optional)
- estat-mcp (optional)
- DBHub

4. 音声・補助処理層
- TTS

5. 永続データ層
- PostgreSQL

## サービス別仕様

### フロントアプリ
- 種別: Next.js ベースの会話フロントエンド
- 既定ポート: 3000
- 主な役割:
  - チャット UI
  - TTS/STT 連携
  - ドメイン選択
  - BFF 経由の injection-tool 呼び出し
- 主要接続先:
  - injection-tool
  - TTS
  - Ollama または OpenAI 互換 LLM

### injection-tool
- 種別: Next.js ベースの管理 UI + BFF
- 既定ポート: 4001
- 主な役割:
  - `/api/intercept` による知識注入
  - ドメイン、MCP、公開設定、共有ログの管理
  - 公開 API と管理 API の提供
  - Cloudflare Quick Tunnel 管理
- 主要接続先:
  - フロントアプリ
  - mcp-server
  - google-workspace-mcp (利用時)
  - estat-mcp (利用時)
  - DBHub
  - TTS

### mcp-server
- 種別: Python MCP テスト/ルーターサーバー
- 既定ポート: 8000
- 主な役割:
  - MCP 接続テスト
  - echo、時刻取得、モック機能などの提供

### google-workspace-mcp
- 種別: FastMCP ベースの Google Workspace 統合サーバー
- 基本スタック外の optional サービス
- 既定ポート: 8001 をホスト公開、コンテナ内部は 8000
- 主な役割:
  - Gmail、Drive、Calendar、Docs、Sheets、Slides、Forms、Tasks、Contacts、Chat、Search
  - OAuth 2.x による認証
  - single-user mode または共有運用

### estat-mcp
- 種別: e-Stat API クライアント兼 MCP サーバー
- 基本スタック外の optional サービス
- 既定ポート: 8002 をホスト公開、コンテナ内部は 8000
- 主な役割:
  - 統計テーブル検索
  - メタデータ取得
  - 統計データ取得
  - 自動ページネーション

### TTS
- 種別: 音声合成サーバー
- 既定ポート: 5000
- 主な役割:
  - テキストから音声を生成
  - CPU / CUDA / host 実行切替

### PostgreSQL と DBHub
- PostgreSQL 既定ポート: 5432
- DBHub 既定ポート: 8080
- 主な役割:
  - PostgreSQL への接続と管理
  - DB 向け MCP 的利用の中継または管理 UI

## 主な API 面

### injection-tool
主な API の例:
- `/api/health`
- `/api/intercept`
- `/api/auth/login`
- `/api/domains`
- `/api/knowledges`
- `/api/mcp-servers`
- `/api/public-management`
- `/api/public-management/tunnel`
- `/api/public/sessions`
- `/api/public/domains`
- `/api/public/rate-limit`
- `/api/public/domain-access/login`

### フロントアプリ
フロントアプリ自体は会話 UI ですが、BFF 的に `/api/chat`、`/api/tts`、`/api/injection/*` などの経路を持つ構成で運用できます。

## 設定値の考え方

主要な構成値は [.env.example](../.env.example) と compose ファイルに定義されます。

代表例:
- `AMICA_PORT`
- `INJECTION_TOOL_PORT`
- `MCP_SERVER_PORT`
- `SBV2_PORT`
- `ESTAT_MCP_PORT`
- `DB_PORT`
- `DBHUB_PORT`
- `AMICA_OLLAMA_URL`
- `AMICA_OPENAI_APIKEY`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`
- `ESTAT_APP_ID`
- `CLOUDFLARE_EXTERNAL_URL`
- `SBV2_DEVICE`

## 実行モード

### 開発モード
- `docker-compose.yml + docker-compose.dev.yml`
- Node.js 開発サーバー
- bind mount と polling 有効
- ソース変更を即時反映しやすい

### 本番相当モード
- `docker-compose.yml + docker-compose.prod.yml`
- Dockerfile build で固定化
- 永続データを volume 経由で保持

## 設計上の重要ポイント

- ユーザーの入口はフロントアプリに集中させる
- 管理と知識注入は injection-tool に分離する
- MCP や DB は内部ネットワーク側に閉じる
- TTS は Docker Compose 内の `sbv2` / `piper` サービスとして扱う
- fail-open を前提に、外部連携停止時も UI 全体を落としにくくする

## 関連資料

- 技術スタック: [04_TECH_STACK_JA.md](./04_TECH_STACK_JA.md)
- 構築/配備: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- 設定一覧: [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
