# モデル切り替えマニュアル

## 目的

この資料は、ark-injection-ai-system で利用する実行時モデルを安全に切り替えるための手順をまとめたものです。

対象:
- Amica のテキスト会話モデル
- Amica の画像認識モデル
- Piper の音声モデル

前提:
- モデル実体はこのリポジトリでは配布しません
- 利用するモデルは運用者が別途取得し、ライセンスを確認してください
- `.env` を更新したあとに `docker compose restart` だけでは反映されません
- 環境変数を変更したサービスは `--force-recreate` で再作成します

## 切り替え前の確認

1. 利用したいモデル名またはモデル URL を確定する
2. Ollama を使う場合は対象モデルが pull 済みか確認する
3. Piper を使う場合は ONNX と config.json の URL を用意する
4. UI 固定運用なら `AMICA_MANAGED_CONFIG_KEYS` に対象キーが含まれていることを確認する

確認コマンド例:

```powershell
docker exec ark-amica printenv NEXT_PUBLIC_OLLAMA_MODEL NEXT_PUBLIC_VISION_OLLAMA_MODEL NEXT_PUBLIC_TTS_BACKEND NEXT_PUBLIC_PIPER_URL
```

## 1. テキスト会話モデルを切り替える

変更対象:
- `.env` の `AMICA_OLLAMA_MODEL`
- 必要なら `.env` の `AMICA_OLLAMA_URL`

例:

```dotenv
AMICA_CHATBOT_BACKEND=ollama
AMICA_OLLAMA_URL=http://host.docker.internal:11434
AMICA_OLLAMA_MODEL=qwen3.5:9b
```

事前確認:

```powershell
ollama list
ollama pull qwen3.5:9b
```

反映:

```powershell
docker compose up -d --force-recreate amica
```

確認:

```powershell
docker exec ark-amica printenv NEXT_PUBLIC_OLLAMA_MODEL
```

期待結果:
- `NEXT_PUBLIC_OLLAMA_MODEL` が更新後のモデル名になっている
- Amica の会話応答が新しいモデルで返る

## 2. 画像認識モデルを切り替える

変更対象:
- `.env` の `AMICA_VISION_BACKEND`
- `.env` の `AMICA_VISION_OLLAMA_MODEL`
- 必要なら `.env` の `AMICA_VISION_OLLAMA_URL`

Ollama を使う例:

```dotenv
AMICA_VISION_BACKEND=vision_ollama
AMICA_VISION_OLLAMA_URL=http://host.docker.internal:11434
AMICA_VISION_OLLAMA_MODEL=llava
```

事前確認:

```powershell
ollama list
ollama pull llava
```

反映:

```powershell
docker compose up -d --force-recreate amica
```

確認:

```powershell
docker exec ark-amica printenv NEXT_PUBLIC_VISION_BACKEND NEXT_PUBLIC_VISION_OLLAMA_MODEL
```

期待結果:
- `NEXT_PUBLIC_VISION_BACKEND` が意図した backend になっている
- `NEXT_PUBLIC_VISION_OLLAMA_MODEL` が更新後のモデル名になっている

## 3. Piper の音声モデルを切り替える

変更対象:
- `.env` の `AMICA_TTS_BACKEND`
- `.env` の `AMICA_PIPER_URL`
- `.env` の `PIPER_MODEL_URL`
- `.env` の `PIPER_CONFIG_URL`
- 必要なら `.env` の `PIPER_DEFAULT_LANGUAGE`

例:

```dotenv
AMICA_TTS_BACKEND=piper
AMICA_PIPER_URL=http://piper:8000
PIPER_MODEL_URL=https://example.com/path/to/voice-model.onnx
PIPER_CONFIG_URL=https://example.com/path/to/config.json
PIPER_DEFAULT_LANGUAGE=ja
```

反映:

```powershell
docker compose up -d --force-recreate piper amica
```

確認:

```powershell
docker exec ark-piper printenv PIPER_MODEL_URL PIPER_CONFIG_URL PIPER_DEFAULT_LANGUAGE
Invoke-WebRequest -UseBasicParsing http://localhost:5001/healthz
```

期待結果:
- `ark-piper` が再作成されている
- `healthz` が成功する
- Amica から Piper 経由で音声再生できる

## 4. 切り替えが反映されないときの確認順

1. `.env` の値を保存できているか確認する
2. 対象モデルが Ollama 側に pull 済みか確認する
3. `docker compose restart` ではなく `docker compose up -d --force-recreate ...` を使ったか確認する
4. 実コンテナの環境変数を `docker exec ... printenv` で確認する
5. `AMICA_MANAGED_CONFIG_KEYS` により UI 変更が無効化されていないか確認する
6. `docker-compose.dev.yml` などの override で上書きされていないか `docker compose config` で確認する

確認コマンド例:

```powershell
docker compose config

docker exec ark-amica printenv NEXT_PUBLIC_OLLAMA_MODEL NEXT_PUBLIC_VISION_OLLAMA_MODEL NEXT_PUBLIC_MANAGED_CONFIG_KEYS

docker logs ark-amica --tail 100
docker logs ark-piper --tail 100
```

## 5. 運用上の注意

- `.env` を変えただけでは既存コンテナの環境変数は更新されません
- `AMICA_MANAGED_CONFIG_KEYS` に `ollama_model` や `vision_ollama_model` が含まれている場合、ブラウザ UI では切り替えできません
- Piper の音声モデルライセンスはランタイム本体とは別なので、モデルごとに確認が必要です
- 画像認識モデルは画像入力に対応している必要があります
- Ollama のモデル名は `ollama list` に出る名前と一致させてください

## 関連資料

- [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md)