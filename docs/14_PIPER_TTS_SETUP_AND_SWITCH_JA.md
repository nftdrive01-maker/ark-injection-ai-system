# Piper TTS 導入・切替手順

## 目的

この資料は、ark-injection-ai-system で Amica の TTS を Style-Bert-VITS2-nftdrive から Piper に切り替える手順と、現在の実装前提をまとめたものです。

現行構成の要点:
- Amica 側の既定 TTS は `.env` の `AMICA_TTS_BACKEND` で制御する
- Piper は公式 `ghcr.io/ayutaz/piper-plus/python-inference:dev` を使って起動する
- このリポジトリは特定の音声モデル実体を配布しない
- Amica の Piper proxy は `GET /synthesize` を使い、CLI と同じ推論条件で音声を生成する

## 関連ファイル

- `ark-injection-ai-system/.env`
- `ark-injection-ai-system/docker-compose.yml`
- `piper/docker-compose.yml`
- `amica/src/app/api/piper/route.ts`  （amica-nftdrive のローカル配置先）

## 設定例

`.env` の主な Piper 関連値の例:

```env
AMICA_TTS_BACKEND=piper
AMICA_PIPER_URL=http://piper:8000
PIPER_PORT=5001
PIPER_MODEL_URL=https://example.com/path/to/voice-model.onnx
PIPER_CONFIG_URL=https://example.com/path/to/config.json
PIPER_DEFAULT_LANGUAGE=ja
PIPER_DEVICE=cpu
PIPER_LENGTH_SCALE=1.0
PIPER_NOISE_SCALE=0.667
```

公開リポジトリ自体は特定の音声モデルを同梱しません。

管理固定の主なキー:

```env
AMICA_MANAGED_CONFIG_KEYS=chatbot_backend,ollama_url,ollama_model,vision_backend,vision_ollama_url,vision_ollama_model,tts_backend,piper_url
```

このため、Amica のブラウザ設定画面から `tts_backend` と `piper_url` は変更できません。

## 前提条件

- Docker Desktop が起動していること
- `ark-injection-ai-system`、`amica`（amica-nftdrive のローカル配置先）、`injection-tool`、`piper` が同一ワークスペース内で相対配置されていること
- `http://localhost:3000` で Amica を起動できること

## Piper を既定 TTS として使う手順

### 1. `.env` を確認する

最低限、以下が設定されていることを確認します。

```env
AMICA_TTS_BACKEND=piper
AMICA_PIPER_URL=http://piper:8000
PIPER_MODEL_URL=<your-model-url>
PIPER_CONFIG_URL=<your-config-url>
PIPER_DEFAULT_LANGUAGE=ja
PIPER_DEVICE=cpu
PIPER_LENGTH_SCALE=1.0
PIPER_NOISE_SCALE=0.667
```

`PIPER_MODEL_URL` と `PIPER_CONFIG_URL` は、利用する音声モデルに合わせて運用者が設定してください。上記 URL は参考例です。

### 2. 対象サービスを再作成する

```powershell
cd D:\ark-injection-ai-system
docker compose up -d --force-recreate piper injection-tool amica
```

補足:
- `docker restart` ではなく `--force-recreate` を使う
- 初回は公式イメージ pull と、設定したモデル URL からの download が入るので少し時間がかかる
- `piper/data` にモデルが保存される

### 2.1 モデル切替後は最適化キャッシュを削除する

モデル URL を変えたあとや、声が変わらない場合は、古い ONNX 最適化キャッシュが残っていることがあります。

```powershell
Remove-Item d:\piper\data\model.cpu.opt.onnx -Force -ErrorAction SilentlyContinue
Remove-Item d:\piper\data\model.cpu.opt.onnx.ok -Force -ErrorAction SilentlyContinue
docker compose up -d --force-recreate piper amica
```

補足:
- このキャッシュが残ると、新しい `model.onnx` を置いても古い最適化済みモデルを読み込むことがあります
- 実際に声が変わらない場合は、まずこの 2 ファイルの削除を優先してください

### 3. サービス起動を確認する

```powershell
docker compose ps piper injection-tool amica
```

期待状態:
- `ark-piper` が `Up`
- `ark-amica` が `Up`
- `ark-injection-tool` が `Up`

## 動作確認

### 1. Piper health 確認

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:5001/health | Select-Object -ExpandProperty Content
```

期待内容の例:

```json
{"status":"healthy"}
```

### 2. Amica の Piper proxy 確認

```powershell
Invoke-WebRequest -UseBasicParsing \
  -Method POST \
  -ContentType 'application/json; charset=utf-8' \
  -OutFile d:\piper\out\amica-piper-ja-test.wav \
  -Uri http://localhost:3000/api/piper/ \
  -Body ([System.Text.Encoding]::UTF8.GetBytes('{"text":"こんにちは、Piperの日本語モデルのテストです。"}'))
```

成功すると `d:\piper\out\amica-piper-ja-test.wav` が生成されます。

必要なら Piper の native エンドポイントを直接確認できます。`language` パラメータは利用モデルに合わせて変更してください。

```powershell
Invoke-WebRequest -UseBasicParsing \
  -Method GET \
  -OutFile d:\piper\out\official-piper-ja-test.wav \
  -Uri "http://localhost:5001/synthesize?text=%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF%E3%80%81Piper%E3%81%AE%E3%83%86%E3%82%B9%E3%83%88%E3%81%A7%E3%81%99%E3%80%82&language=ja&speaker_id=0&noise_scale=0.667&length_scale=1.5&noise_w=0.8"
```

### 3. 実アプリ確認

1. `http://localhost:3000` を開く
2. チャット送信を行う
3. 応答音声が Piper で再生されることを確認する

## Style-Bert-VITS2-nftdrive に戻す手順

`ark-injection-ai-system/.env` の以下を戻します。

```env
AMICA_TTS_BACKEND=stylebertvits2
```

必要に応じて `SBV2_INTERNAL_URL` 側も見直したうえで、再作成します。

```powershell
cd D:\ark-injection-ai-system
docker compose up -d --force-recreate amica
```

SBV2 側も含めて構成を戻したい場合:

```powershell
docker compose up -d --force-recreate sbv2 amica
```

## 公式 Piper 実装の注意点

- 利用する音声モデルが `piper-plus` 専用か、upstream Piper 互換かは配布元の説明を確認してください
- そのため `ghcr.io/ayutaz/piper-plus/python-inference:dev` の公式 runtime を使います
- Amica は [amica/src/app/api/piper/route.ts](../amica/src/app/api/piper/route.ts)（amica-nftdrive のローカル配置先）から `GET /synthesize` へ中継します
- PowerShell から日本語を直接テストする場合は UTF-8 バイトで送るほうが確実です
- モデル差し替え後は `model.cpu.opt.onnx` のキャッシュ削除もセットで行うほうが安全です

## トラブル時の確認ポイント

### Piper ログ

```powershell
docker logs ark-piper --tail 200
```

### Amica ログ

```powershell
docker logs ark-amica --tail 200
```

### 実環境変数の確認

```powershell
docker exec ark-amica printenv NEXT_PUBLIC_TTS_BACKEND NEXT_PUBLIC_PIPER_URL PIPER_URL
```

期待値:
- `NEXT_PUBLIC_TTS_BACKEND=piper`
- `NEXT_PUBLIC_PIPER_URL=http://piper:8000`
- `PIPER_URL=http://piper:8000`

## 既知の注意

- モデルや config を変えた後は `piper` の再作成が必要
- モデルや config を変えた後は `piper/data/model.cpu.opt.onnx` と `piper/data/model.cpu.opt.onnx.ok` を削除してから再作成する
- ブラウザから Piper を直接叩くのではなく、Amica の `/api/piper/` proxy 経由で使う
- `piper/data` を削除するとモデルを再ダウンロードする
- `piper/data/.source.json` で前回の model/config URL を保持しているため、URL を変えた場合も再作成時に自動で再取得される

## 関連資料

- [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)