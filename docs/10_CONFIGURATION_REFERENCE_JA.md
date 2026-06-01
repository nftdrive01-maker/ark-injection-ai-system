# 設定リファレンス

## 目的

この資料は `ark-injection-ai-system/.env.example` と compose 定義を基に、主要設定値の意味と変更タイミングを整理したものです。

## コア設定

| 変数名 | 既定値 | 意味 | 変更タイミング | 注意 |
|---|---|---|---|---|
| COMPOSE_PROJECT_NAME | ark-injection-ai-system | Compose プロジェクト名 | 初回構築時 | 他環境と競合しないようにする |
| AMICA_PORT | 3000 | フロントアプリ公開ポート | 入口ポート変更時 | 公開 URL 変更に注意 |
| INJECTION_TOOL_PORT | 4001 | injection-tool 公開ポート | 管理面ポート変更時 | 原則外部非公開 |
| MCP_SERVER_PORT | 8000 | mcp-server 公開ポート | テスト用途変更時 | 原則外部非公開 |
| SBV2_PORT | 5000 | TTS 公開ポート | TTS ポート変更時 | Compose の `sbv2` サービスと整合を取る |
| ESTAT_MCP_PORT | 8002 | estat-mcp 公開ポート | e-Stat 接続面変更時 | 原則外部非公開 |
| DB_PORT | 5432 | PostgreSQL ポート | DB 設計変更時 | 原則外部非公開 |
| DBHUB_PORT | 8080 | DBHub 公開ポート | DB 管理 UI 変更時 | 原則外部非公開 |

## LLM / AI 関連

| 変数名 | 既定値 | 意味 | 注意 |
|---|---|---|---|
| AMICA_CHATBOT_BACKEND | ollama | フロントアプリの既定 LLM backend | Ollama 以外を使う場合は関連 URL も確認 |
| AMICA_DEFAULT_SHOW_CHAT_MODE | true | 初期表示モード | UI 方針に応じて調整 |
| AMICA_ASYNC_TTS_MODE | false | AI メッセージ表示を TTS 取得より先行させるか | true で表示先行、false で従来動作 |
| AMICA_OLLAMA_URL | http://host.docker.internal:11434 | Ollama 接続先 | Docker から見える URL である必要あり |
| AMICA_OLLAMA_MODEL | qwen2.5:7b | テキスト会話用 Ollama モデル | Ollama 側に pull 済みである必要あり |
| AMICA_VISION_BACKEND | vision_ollama | 画像認識の既定 backend | vision_ollama / vision_openai / vision_llamacpp を想定 |
| AMICA_VISION_OLLAMA_URL | http://host.docker.internal:11434 | 画像認識用 Ollama 接続先 | 未分離運用では AMICA_OLLAMA_URL と同じでよい |
| AMICA_VISION_OLLAMA_MODEL | llava | 画像認識用 Ollama モデル | 画像対応モデルが必要 |
| AMICA_MANAGED_CONFIG_KEYS | chatbot_backend,ollama_url,ollama_model,vision_backend,vision_ollama_url,vision_ollama_model,tts_backend,piper_url | UI から変更不可にする設定キー一覧 | localStorage より環境変数を優先させたい項目を指定 |
| AMICA_HIDDEN_SETTINGS_PAGES | 空 | 設定画面で非表示にするページ一覧 | chatbot,tts,stt,vision,developer,external_api をカンマ区切りで指定 |
| AMICA_OPENAI_APIKEY | 空 | OpenAI API キー | 機密情報 |
| AMICA_OPENAI_URL | https://api.openai.com | OpenAI API 接続先 | 互換 API へ差し替え可能 |
| AMICA_OPENAI_MODEL | gpt-4o-mini | OpenAI 既定モデル | コストと品質のバランスに応じて変更 |

### Amica の一括管理について

- `AMICA_MANAGED_CONFIG_KEYS` に含めた設定は、Amica のクライアント設定画面から変更できません
- Vision を Ollama で一括管理する場合は `AMICA_VISION_BACKEND=vision_ollama` を基本にし、必要なら `AMICA_VISION_OLLAMA_URL` と `AMICA_VISION_OLLAMA_MODEL` を合わせて指定します
- テキスト会話と画像認識で別の Ollama サーバーを使いたい場合は、`AMICA_OLLAMA_URL` と `AMICA_VISION_OLLAMA_URL` を分けて設定します
- これらの環境変数を変更した後は、`docker compose up -d --force-recreate amica` でコンテナ再作成が必要です

## TTS 関連

| 変数名 | 既定値 | 意味 | 注意 |
|---|---|---|---|
| SBV2_DEVICE | cpu | SBV2 コンテナの推論デバイス | `cuda` 指定時は Docker から GPU が見える必要がある |
| AMICA_TTS_BACKEND | stylebertvits2 または piper | Amica の既定 TTS backend | UI から固定したい場合は managed key に含める |
| AMICA_PIPER_URL | http://piper:8000 | Amica から見た Piper URL | Amica は `/api/piper/` proxy 経由で利用 |
| PIPER_PORT | 5001 | ホスト公開する Piper ポート | `http://localhost:5001/healthz` で確認可能 |
| PIPER_MODEL_URL | 空 | Piper が読み込む ONNX モデル | このリポジトリでは音声モデルを配布しないため、利用者が別途設定する |
| PIPER_CONFIG_URL | 空 | モデル対応の設定ファイル | ONNX と組で整合が必要 |
| PIPER_DEFAULT_LANGUAGE | ja | 選択した音声モデルの既定言語 | 利用モデルに応じて変更する |

## Google Workspace 関連

| 変数名 | 既定値 | 意味 | 注意 |
|---|---|---|---|
| GOOGLE_OAUTH_CLIENT_ID | なし | Google OAuth Client ID | 機密に準ずる扱い |
| GOOGLE_OAUTH_CLIENT_SECRET | なし | Google OAuth Client Secret | 機密情報 |
| CLOUDFLARE_EXTERNAL_URL | 空 | 外部公開 URL | callback URL と整合が必要 |

## e-Stat 関連

| 変数名 | 既定値 | 意味 | 注意 |
|---|---|---|---|
| ESTAT_APP_ID | 空 | e-Stat API の appId | 未設定だと実質利用不可 |

## DB 関連

| 変数名 | 既定値 | 意味 | 注意 |
|---|---|---|---|
| DB_USER | user | PostgreSQL ユーザー名 | 本番では見直し推奨 |
| DB_PASSWORD | password | PostgreSQL パスワード | 既定値のまま使わない |
| DB_NAME | dbname | PostgreSQL DB 名 | システム設計に応じて変更 |

## Compose 差分で決まる設定

### docker-compose.dev.yml
- Node.js 開発サーバーを利用
- bind mount を利用
- `WATCHPACK_POLLING=true`
- `CHOKIDAR_USEPOLLING=true`
- SBV2 は `Dockerfile.infer` を使う
- Amica / injection-tool の SBV2 接続先は base compose に従う

### docker-compose.prod.yml
- フロントアプリと injection-tool を Dockerfile build する
- injection-tool の data を永続化する

### docker-compose.lan-https.yml
- Caddy を追加する
- 443 / 3443 の HTTPS 入口を提供する

## 変更時の指針

- ポート変更時は公開 URL、疎通確認、OAuth callback を合わせて見直す
- SBV2 の CPU / CUDA 切替時は `.env` の `SBV2_DEVICE` と Docker の GPU 利用可否をセットで確認する
- 本番相当構成では既定の DB パスワードを絶対に使わない
- Cloudflare 公開時は外部 URL を設定した後に関連コンテナを再作成する

## 参照元

- `ark-injection-ai-system/.env.example`
- `ark-injection-ai-system/docker-compose.yml`
- `ark-injection-ai-system/docker-compose.dev.yml`
- `ark-injection-ai-system/docker-compose.prod.yml`
- `ark-injection-ai-system/docker-compose.lan-https.yml`

## 関連資料

- 構築手順: [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- セキュリティ: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- 障害対応: [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- Piper 手順: [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md)
