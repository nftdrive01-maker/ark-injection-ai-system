# 技術スタック

## 技術スタック一覧

| 領域 | 採用技術 | 主な役割 |
|---|---|---|
| フロントエンド | Next.js, React, TypeScript | フロントアプリ UI と injection-tool UI |
| スタイリング | Tailwind 系ユーティリティクラス中心 | UI 構築 |
| BFF / 管理 API | Next.js Route Handlers | injection-tool の管理 API、公開 API |
| AI 会話基盤 | Ollama, OpenAI 互換 API | LLM 応答生成 |
| 音声合成 | 音声合成エンジン | TTS |
| 音声入力 | Whisper 系、Web Speech API、VAD | STT とマイク制御 |
| MCP | FastMCP / MCP サーバー群 | 外部ツール接続 |
| 統計データ | estat-mcp | e-Stat 接続 |
| Google 連携 | google-workspace-mcp | Workspace 接続 |
| テスト MCP | mcp-server | 接続確認・簡易ツール |
| データベース | PostgreSQL 15 | 永続データ |
| DB ゲートウェイ | Bytebase DBHub | DB 接続・操作 |
| コンテナ | Docker, Docker Compose | マルチサービス統合起動 |
| 公開 | Cloudflare Tunnel, Caddy | 外部公開、LAN HTTPS |
| 認証 | Google OAuth 2.x, 管理者トークン, ドメイン認証 | 管理画面・Workspace・公開制御 |

## 採用理由

### Next.js / React / TypeScript
フロントアプリと injection-tool の両方で利用されています。UI と API を同じ技術系で扱えるため、管理画面とフロントエンドを保守しやすく、型安全性も確保しやすい構成です。

### Docker Compose
複数サービスをまとめて起動・停止・切替しやすいため、PoC、デモ、ローカル開発、本番相当検証まで同じ構成思想で運用できます。

### TTS エンジン
日本語 TTS に適しており、CPU と CUDA を切替しながら運用できます。Docker でもホスト実行でも扱えるため、マシン制約や性能要件に合わせやすい点が利点です。

### MCP サーバー群
Google Workspace、e-Stat、DB などの外部ソースを AI に統合するための接続層です。知識注入と分離することで、データソースごとの責務が明確になります。

### PostgreSQL + DBHub
RDB を利用したデータ保持や検索系ユースケースに対応しやすく、DBHub によって接続面や管理面を分離できます。

### Cloudflare Tunnel / Caddy
Cloudflare Tunnel はインターネット向けの簡易公開に向き、Caddy は LAN 内 HTTPS の提供に向いています。用途ごとに公開方式を選べます。

## サービス別採用技術

### フロントアプリ
- Next.js
- React
- TypeScript
- three.js / VRM 関連
- Whisper / Web Speech / VAD
- TTS 連携
- Ollama / OpenAI 互換 LLM 連携

### injection-tool
- Next.js
- React
- TypeScript
- Route Handlers
- JSON ファイルベース設定管理
- MCP ランタイム制御
- Cloudflare Tunnel 制御

### google-workspace-mcp
- Python
- FastMCP
- Google OAuth 2.x
- Google Workspace API 群

### estat-mcp
- Python
- Pydantic
- e-Stat API
- MCP サーバー

### mcp-server
- Python
- MCP テストサーバー

## 非機能要件に対するスタック上の考え方

### 可用性
- fail-open を採りやすい分離構成
- 一部サービス障害でも会話 UI 全停止を避けやすい

### 拡張性
- 新しい MCP サーバーを injection-tool へ登録しやすい
- ドメイン単位で設定を増やしやすい
- LLM と TTS を差し替えやすい

### 運用性
- Docker Compose により起動手順を標準化
- 管理画面で運用設定を UI 化
- Cloudflare Tunnel など公開制御を手順化しやすい

### セキュリティ
- 内部面を BFF の後ろへ置きやすい
- OAuth や管理者認証をサービスごとに分離可能
- レート制限や公開設定を injection-tool 側で制御可能

## 関連資料

- 技術仕様: [03_TECHNICAL_SPEC_JA.md](./03_TECHNICAL_SPEC_JA.md)
- セットアップ: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- セキュリティ: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
