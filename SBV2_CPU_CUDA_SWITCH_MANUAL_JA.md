# TTS CPU/CUDA 切り替えマニュアル

この手順は、現在の構成（フロントアプリ / injection-tool / mcp-server / SBV2 / Piper を Docker Compose で起動）を前提にしています。

## 1. 前提

- 作業フォルダ: `D:\ark-injection-ai-system`
- SBV2 は Compose サービス `sbv2` として起動する
- 初回は `sbv2-init` が BERT / デフォルト推論モデルを準備する

## 2. 設定ファイルで切り替える項目

編集対象: `.env`

### CPU にする

```env
SBV2_DEVICE=cpu
```

### CUDA にする

```env
SBV2_DEVICE=cuda
```

補足:
- Amica / injection-tool の SBV2 接続先は常に `http://sbv2:5000` です
- GPU を実際に使うには、Docker 側で GPU が使える構成である必要があります

## 3. 切り替え手順（CPU/CUDA 共通）

以下を実行します。

```powershell
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1 -Build
```

2回目以降は通常 `-Build` なしで構いません。

```powershell
.\scripts\dev-up-container-sbv2.ps1
```

## 4. 正常起動の確認

### 4-1. Docker 側コンテナ

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}"
```

期待値:
- `ark-amica`
- `ark-injection-tool`
- `ark-mcp-server`
- `ark-sbv2`
- `ark-piper`

### 4-2. TTS の疎通

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

期待値:
- `StatusCode: 200`

### 4-3. フロントアプリの TTS 接続先

```powershell
docker inspect ark-amica --format "{{range .Config.Env}}{{println .}}{{end}}" | findstr STYLEBERTVITS2
```

期待値:
- `NEXT_PUBLIC_STYLEBERTVITS2_SERVER_URL=http://sbv2:5000`
- `STYLEBERTVITS2_URL=http://sbv2:5000`

## 5. 初回起動で準備されるもの

`sbv2-init` は `initialize.py --only_infer` を実行し、以下を準備します。

- 日本語 BERT モデル
- デフォルト推論用の音声モデル

注意:
- 独自の音声モデルは `model_assets` 配下に別途配置してください
- Hugging Face 側に問題があると、初回起動で `sbv2-init` が失敗します

## 6. よくあるエラーと対処

### `Models not found in model_assets`

- `sbv2-init` が失敗しているか、`model_assets` に有効なモデルがない状態です
- `docker logs ark-sbv2-init` を確認してください

### `/docs` は開くが、特定モデルで音声合成できない

- `model_assets/<モデル名>/config.json`
- `model_assets/<モデル名>/style_vectors.npy`
- `model_assets/<モデル名>/*.safetensors`

の組み合わせが揃っているか確認してください

### CUDA にしたのに速くならない

- Docker が GPU を利用できる構成か確認してください
- SBV2 コンテナ内で `torch.cuda.is_available()` が真になる必要があります
- 短文では CPU と CUDA の差が体感しにくいことがあります

## 7. トラブル時の最短診断コマンド集

### 7-1. Compose 設定の確認

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml config
```

### 7-2. SBV2 初期化ログ

```powershell
docker logs ark-sbv2-init
```

### 7-3. SBV2 本体ログ

```powershell
docker logs ark-sbv2
```

### 7-4. 接続先確認

```powershell
docker inspect ark-amica --format "{{range .Config.Env}}{{println .}}{{end}}" | findstr STYLEBERTVITS2
```
```

期待値:
- `NEXT_PUBLIC_STYLEBERTVITS2_SERVER_URL=http://host.docker.internal:5000`
- `STYLEBERTVITS2_URL=http://host.docker.internal:5000`

### 9-4. .env の実設定確認

```powershell
Get-Content .\.env
```

見るポイント:
- `SBV2_DEVICE` が意図した値（cpu/cuda）
- `SBV2_HOST_INTERNAL_URL` が host モード用 URL

### 9-5. CUDA 利用可否の確認（ホスト venv）

```powershell
D:\sbv2\Style-Bert-VITS2\venv\Scripts\python.exe -c "import torch; print('cuda_available=', torch.cuda.is_available()); print('device_count=', torch.cuda.device_count())"
```

期待値:
- `cuda_available= True`
- `device_count= 1` 以上

### 9-6. GPU/VRAM の監視

```powershell
nvidia-smi -l 1
```

見るポイント:
- TTS リクエスト時に GPU 使用率が上がるか
- OOM が出るほど VRAM が逼迫していないか

### 9-7. すぐ復旧するための再起動 3 点セット

```powershell
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1
```
