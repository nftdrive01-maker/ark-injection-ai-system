# システム概要

## 3分サマリー

ark-injection-ai-system は、会話 UI、知識注入管理、MCP 連携、音声合成、データベースをまとめて動かす統合 AI システムです。

このシステムの中核は、フロントアプリを会話フロントエンド、injection-tool を知識注入と管理画面、MCP サーバー群を外部データ接続層として組み合わせている点にあります。ユーザーはフロントアプリから自然言語で対話し、管理者は injection-tool でドメインごとの知識、MCP サーバー、公開設定、レート制限、Cloudflare トンネルなどを制御できます。

主な特徴:
- 会話 UI と管理 UI を分離した fail-open 構成
- ドメインごとに知識、外部連携、見た目、音声設定を切り替え可能
- Google Workspace、e-Stat、DBHub などを MCP 経由で統合可能
- TTS による音声出力を Docker またはホスト実行で切替可能
- Cloudflare Tunnel や LAN HTTPS による外部公開に対応

## このシステムでできること

### 1. 会話型 AI フロントエンドの提供
フロントアプリがユーザー向け UI を提供します。音声入力、音声出力、チャット UI、履歴、ドメイン切替、視線起動や Ark-i Core 表示などを担当します。

### 2. ドメイン別の知識注入
injection-tool は、ユーザーの問い合わせ内容と選択ドメインに応じて、追加のシステムプロンプトや関連知識を注入します。これにより、単一の LLM でも業務別・用途別に応答品質を切り替えられます。

### 3. 外部データソース連携
MCP 経由で Google Workspace、e-Stat、DB、テスト用 MCP サーバーなどと連携できます。統計値、メール、ドライブ情報、DB オブジェクト探索などを会話フローに取り込めます。

### 4. 管理者向け運用
管理者は injection-tool の管理画面から以下を操作できます。
- ドメインの追加・編集・削除
- MCP サーバーの登録・更新
- 公開設定とレート制限
- Cloudflare Quick Tunnel の起動・停止
- 共有ログやチャット履歴関連の設定

## 想定ユースケース

- 施設案内、相談窓口、社内ナレッジ案内の AI フロント
- Google Workspace や社内 DB を参照する業務支援 AI
- e-Stat を使った統計 QA デモ、分析補助、政策説明補助
- 展示会やデモ環境向けの対話型プレゼンテーション UI
- LAN 内限定または Cloudflare 経由の限定公開 AI システム

## システムを構成する主要サービス

基本スタックはフロントアプリ / injection-tool / mcp-server / TTS / PostgreSQL / DBHub です。  
`google-workspace-mcp` と `estat-mcp` は必要時のみ追加する optional サービスとして扱えます。

| サービス | 役割 | 既定ポート |
|---|---|---:|
| フロントアプリ | ユーザー向け会話 UI | 3000 |
| injection-tool | 知識注入、管理画面、公開設定 API | 4001 |
| mcp-server | 汎用 MCP ルーター/テスト用接続先 | 8000 |
| google-workspace-mcp | Google Workspace 連携 / optional | 8001 |
| estat-mcp | e-Stat 統計連携 / optional | 8002 |
| TTS | 音声合成 | 5000 |
| PostgreSQL | 永続データ保存 | 5432 |
| DBHub | DB 操作用ゲートウェイ/UI | 8080 |

## 提供価値

### ビジネス面
- データ更新や用途切替をコード改修なしで運用側に寄せられる
- デモ環境から業務向け PoC まで同じ構成思想で展開できる
- UI、知識、外部データ、音声を一体で見せられる

### 技術面
- フロント、BFF、MCP、TTS、DB を分離しやすい構成
- 公開時もフロントアプリを入口にして内部面を隠しやすい
- 特定サービス停止時も全体停止しにくい fail-open 設計を取りやすい

## 関連資料

- 全体構成: [02_ARCHITECTURE_AND_DATAFLOW_JA.md](./02_ARCHITECTURE_AND_DATAFLOW_JA.md)
- 技術仕様: [03_TECHNICAL_SPEC_JA.md](./03_TECHNICAL_SPEC_JA.md)
- セキュリティ: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- 構築手順: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
