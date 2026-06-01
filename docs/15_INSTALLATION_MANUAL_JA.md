# インストールマニュアル

このドキュメントは、ark-injection-ai-system を新規に導入する人向けの最短手順です。

対象:
- Windows 上で開発 / 検証環境を立ち上げたい人
- Docker Compose ベースで Amica / injection-tool / MCP / TTS をまとめて起動したい人
- SBV2 を完全コンテナ運用し、CPU / GPU を環境変数で切り替えたい人

## 1. 前提ソフト

必須:
- Windows
- Docker Desktop
- PowerShell
- Git

任意:
- Ollama
- cloudflared
- mkcert

GPU で SBV2 を動かしたい場合の追加前提:
- NVIDIA GPU
- GPU ドライバ
- Docker Desktop から GPU を利用できる構成

## 2. リポジトリ配置

`ark-injection-ai-system` を先に clone している場合は、以下のスクリプトで関連リポジトリの clone と `.env` の初期生成をまとめて実行できます。

```powershell
cd D:\ark-injection-ai-system
.\scripts\setup-workspace.ps1 -ChatBackend chatgpt
```

Google Workspace MCP と e-Stat MCP を後回しにしたい場合は、次のように clone 対象と workspace 登録から外せます。

```powershell
.\scripts\setup-workspace.ps1 -ChatBackend chatgpt -SkipGoogleWorkspaceMcp -SkipEstatMcp
```

補足:
- `-ChatBackend chatgpt` は OpenAI 系、`-ChatBackend ollama` は Ollama 系の初期値で `.env` を生成します
- `-SkipGoogleWorkspaceMcp` と `-SkipEstatMcp` は該当リポジトリを clone 対象と `.code-workspace` から外します
- Google Workspace MCP 用の OAuth 情報、音声モデル、アバター素材、キャラクターモデルは別途用意が必要です
- 開発スタックも続けて起動したい場合は `-StartStack` を追加してください。これは基本スタックのみを起動し、`google-workspace-mcp` と `estat-mcp` は含みません
- Ark-i Core の CSS ベース既定表示はこの構成に含まれますが、音声を出すには別途音声モデル設定が必要です
- Piper を使う場合は `.env` の `PIPER_MODEL_URL` と `PIPER_CONFIG_URL` を設定してください。詳細は [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md) を参照してください

Google Workspace MCP と e-Stat MCP も起動したい場合:

```powershell
.\scripts\dev-up-container-sbv2.ps1 -Build -IncludeGoogleWorkspaceMcp -IncludeEstatMcp
```

以下のように並列配置してください。

- `D:\ark-injection-ai-system`
- `D:\amica`  （amica-nftdrive のローカル配置先）
- `D:\injection-tool`
- `D:\mcp-server`
- `D:\google-workspace-mcp`
- `D:\estat-mcp`
- `D:\sbv2\Style-Bert-VITS2`  （Style-Bert-VITS2-nftdrive のローカル配置先）

理由:
- Compose が `../amica`（amica-nftdrive のローカル配置先）や `../injection-tool` を bind mount するためです

## 3. 初回設定

`D:\ark-injection-ai-system\.env.example` を元に `D:\ark-injection-ai-system\.env` を作成します。

最低限確認する項目:
- `INJECTION_ADMIN_USERNAME`: injection-tool 管理画面にログインするユーザー名です
- `INJECTION_ADMIN_PASSWORD`: injection-tool 管理画面にログインするパスワードです
- `INJECTION_SESSION_SECRET`: 管理画面のセッションを保護する秘密値です
- `AMICA_OLLAMA_URL`: Ollama を使う場合の接続先 URL です
- `AMICA_OLLAMA_MODEL`: Ollama を使う場合のモデル名です
- `SBV2_DEVICE`: SBV2 を `cpu` と `cuda` のどちらで動かすかを決めます
- `PIPER_DEVICE`: Piper を `cpu` と `cuda` のどちらで動かすかを決めます

Google Workspace MCP を使う場合に追加で必要な項目:
- `GOOGLE_OAUTH_CLIENT_ID`: Google Workspace MCP 用の OAuth クライアント ID です
- `GOOGLE_OAUTH_CLIENT_SECRET`: Google Workspace MCP 用の OAuth クライアントシークレットです

使い分けの目安:
- OpenAI を使う場合は `AMICA_CHATBOT_BACKEND=chatgpt` と API キー系を設定します
- Ollama を使う場合は `AMICA_CHATBOT_BACKEND=ollama` と `AMICA_OLLAMA_URL` / `AMICA_OLLAMA_MODEL` を設定します
- Google Workspace MCP を使う場合は上記の OAuth 項目も設定します

最初は以下を推奨します。

```env
SBV2_DEVICE=cpu
PIPER_DEVICE=cpu
AMICA_TTS_BACKEND=piper
```

補足:
- SBV2 の接続先は Compose 内で常に `http://sbv2:5000` です
- host モードは廃止済みです
- 音声モデル、アバター画像、Live2D / VRM などのキャラクター素材は別途用意が必要です

## 4. CPU での初回起動

最初は CPU で動作確認してください。

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-up-container-sbv2.ps1 -Build
```

この起動で以下が立ち上がります。

- `ark-amica`
- `ark-injection-tool`
- `ark-mcp-server`
- `ark-sbv2-init`
- `ark-sbv2`
- `ark-piper`

補足:
- `sbv2-init` は初回に BERT とデフォルト推論モデルを取得します
- 初回は数分かかることがあります
- Piper の音声モデルや表示用素材は公開リポジトリに含まれないため、必要に応じて別途配置してください

## 5. GPU 利用前の事前確認

GPU を使いたい場合は、`up` の前に一度だけ確認してください。

### 5-1. ホストで GPU が見えるか

```powershell
nvidia-smi
```

### 5-2. Docker から GPU コンテナを実行できるか

```powershell
docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi
```

このコマンドが失敗する場合、`SBV2_DEVICE=cuda` にしても SBV2 は GPU を使えません。

## 6. GPU での起動

事前確認が通ったら `.env` を更新します。

```env
SBV2_DEVICE=cuda
```

その後、再起動します。

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1 -Build
```

補足:
- GPU 利用には Docker 側の GPU 割り当てが通っている必要があります
- `SBV2_DEVICE=cuda` はアプリ側の指定であり、Docker 側の GPU 利用可否とは別です

## 7. 起動確認

### 7-1. コンテナ一覧

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
```

### 7-2. フロントアプリ

- `http://localhost:3000`

### 7-3. injection-tool

- `http://localhost:4001`
- `http://localhost:4001/login`

### 7-4. SBV2 API

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

### 7-5. SBV2 接続先確認

```powershell
docker inspect ark-amica --format "{{range .Config.Env}}{{println .}}{{end}}" | findstr STYLEBERTVITS2
```

期待値:
- `NEXT_PUBLIC_STYLEBERTVITS2_SERVER_URL=http://sbv2:5000`
- `STYLEBERTVITS2_URL=http://sbv2:5000`

### 7-6. GPU 認識確認

```powershell
docker exec ark-sbv2 python -c "import torch; print(torch.cuda.is_available())"
```

期待値:
- CPU 運用時: `False`
- GPU 運用時: `True`

## 8. 初回ログイン

`http://localhost:4001/login` にアクセスし、`.env` に設定した以下でログインします。

- `INJECTION_ADMIN_USERNAME`
- `INJECTION_ADMIN_PASSWORD`

## 9. よくある詰まりどころ

### `ark-sbv2` が起動しない

以下を確認してください。

```powershell
docker logs ark-sbv2-init --tail 200
docker logs ark-sbv2 --tail 200
```

典型例:
- Hugging Face からの初回取得失敗
- `model_assets` が空
- GPU 指定なのに Docker から GPU が見えていない

### `STYLEBERTVITS2_URL` が host を向いている

旧 host モードの設定や古い compose を使っていないか確認してください。

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml config
```

### GPU のつもりで実は CPU 動作している

以下を確認してください。

```powershell
docker exec ark-sbv2 python -c "import torch; print(torch.cuda.is_available(), torch.cuda.device_count())"
```

## 10. 停止

```powershell
cd D:\ark-injection-ai-system
.\scripts\dev-down-container-sbv2.ps1
```

## 11. 次に読む資料

- [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- [16_MODEL_SWITCH_MANUAL_JA.md](./16_MODEL_SWITCH_MANUAL_JA.md)
- [SBV2_CPU_CUDA_SWITCH_MANUAL_JA.md](../SBV2_CPU_CUDA_SWITCH_MANUAL_JA.md)