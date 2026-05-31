# セキュリティと公開方針

## 基本方針

ark-injection-ai-system では、外部公開時に内部サービスを直接見せないことが重要です。原則として公開入口はフロントアプリのみとし、injection-tool、MCP サーバー、DBHub、PostgreSQL、TTS は内部ネットワーク側に留めます。

## 公開面の設計

### 公開してよい面
- フロントアプリの入口
- 必要に応じて HTTPS 化されたフロントアプリの入口

### 原則として公開しない面
- injection-tool 管理画面
- mcp-server
- google-workspace-mcp
- estat-mcp
- TTS
- DBHub
- PostgreSQL

## 公開方式

### 1. ローカル限定
- 最も安全
- 開発や単独検証向け
- 外部からは到達不可

### 2. LAN HTTPS
- 社内 LAN や閉域ネットワーク向け
- mkcert と Caddy を利用
- インターネット公開より安全に制御しやすい

### 3. Cloudflare Tunnel
- デモや限定公開に向く
- 一時 URL または Zero Trust 構成を利用
- 公開範囲の設定を誤ると情報露出が起こりやすい

## 認証と制御

### 管理画面認証
injection-tool の管理画面は管理者認証を前提にします。管理ユーザー名・パスワードは既定値のまま使わず、必ず変更してください。

### Google OAuth
Google Workspace 連携では OAuth クレデンシャル管理が必須です。以下を守ってください。
- 自組織の GCP プロジェクトを使う
- 必要最小限のスコープを選ぶ
- callback URL を公開 URL と一致させる
- クレデンシャルをリポジトリへ含めない

### ドメイン公開制御
injection-tool 側には公開ドメイン、セッション、レート制限、トンネル管理があります。公開時は対象ドメインと管理面を分けて考えてください。

### レート制限
chat と TTS は負荷が異なるため、公開時は用途別のレート制限が重要です。特に TTS は文字数依存で重くなりやすいため、チャットとは別枠で設計します。

## 秘密情報の扱い

機密扱いにするべきもの:
- `AMICA_OPENAI_APIKEY`
- `GOOGLE_OAUTH_CLIENT_ID`
- `GOOGLE_OAUTH_CLIENT_SECRET`
- `DB_PASSWORD`
- Cloudflare 運用で使う認証情報

推奨事項:
- `.env` は Git 管理しない
- 本番環境では既定値の DB パスワードを使わない
- OAuth クレデンシャルは環境変数または安全な secret 管理に置く
- 共有端末に平文の設定を残しすぎない

## BFF と内部閉域の重要性

ブラウザから直接 MCP や DB に触らせる設計は避けてください。フロントアプリと injection-tool を経由することで以下を実現しやすくなります。
- 認証と認可の集約
- レート制限の集約
- エラーハンドリングの統一
- 内部 URL の秘匿

## Cloudflare 公開時の注意

- 原則、トンネル対象はフロントアプリの入口だけにする
- 内部面のポート転送を追加しない
- Cloudflare URL 変更時は OAuth callback も更新する
- 可能なら Cloudflare Access や WAF の併用を検討する

## LAN HTTPS の注意

- 自己署名証明書の配布手順を整理する
- 接続先端末へ root CA を適切に導入する
- LAN 内であっても管理画面の露出範囲を絞る

## 運用上の最小チェックリスト

- DB パスワードを変更した
- 管理画面の認証情報を変更した
- OAuth callback URL を現在の公開 URL に合わせた
- 外部公開先がフロントアプリのみであることを確認した
- レート制限を設定した
- Cloudflare または LAN 証明書の運用方法を文書化した

## 参考にすべき既存資料

- ark-injection-ai-system/EXTERNAL_PUBLISH_MANUAL_JA.md
- amica/PUBLIC_DEPLOYMENT_MANUAL_JA.md  （amica-nftdrive のローカル配置先）
- injection-tool/GOOGLE_WORKSPACE_MCP_MANUAL_JA.md
- google-workspace-mcp/README.md

## 関連資料

- 構築手順: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- 管理操作: [07_ADMIN_AND_OPERATOR_MANUAL_JA.md](./07_ADMIN_AND_OPERATOR_MANUAL_JA.md)
- 障害対応: [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
