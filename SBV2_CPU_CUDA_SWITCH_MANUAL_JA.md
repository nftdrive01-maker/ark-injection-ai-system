# SBV2 運用マニュアル

この文書は、ark-injection-ai-system で Style-Bert-VITS2 を Docker Compose 運用するときの専用手順です。

対象:
- SBV2 を初回セットアップしたい人
- CPU と CUDA を切り替えたい人
- 起動確認や障害切り分けをしたい人

## 1. 先に押さえること

- SBV2 は Compose サービス `sbv2` として起動します
- 初回準備は `sbv2-init` が担当します
- `sbv2-init` は `initialize.py --only_infer` を実行し、BERT と既定の推論用モデルを準備します
- 実際の推論デバイス切替は `sbv2-init` ではなく `.env` の `SBV2_DEVICE` で行います
- 公開テンプレートには音声モデル実体を同梱しないため、必要に応じて `model_assets` の追加配置が必要です

補足:
- Amica と injection-tool からの SBV2 接続先は常に `http://sbv2:5000` です
- 既定の `.env` では Amica の TTS バックエンドが Piper になっている場合があります
- そのため、Amica 上で音声が出たかどうかだけでは SBV2 の動作確認にならないことがあります

## 2. 前提条件

作業フォルダ:

```powershell
cd D:\ark-injection-ai-system
```

前提:
- `D:\ark-injection-ai-system` の兄弟階層に `D:\sbv2\Style-Bert-VITS2` が存在する
- Docker Desktop と Docker Compose が使える
- GPU 利用時は Docker から GPU を参照できる

SBV2 関連で参照する主なパス:
- `..\sbv2\Style-Bert-VITS2`
- `..\sbv2\Style-Bert-VITS2\model_assets`
- `..\sbv2\Style-Bert-VITS2\bert`
- `..\sbv2\Style-Bert-VITS2\Data`

## 3. 役割分担

### `sbv2-init`

- 初回セットアップ専用です
- BERT と既定の推論用モデル取得を担当します
- 成功後に `sbv2` が起動できる前提を作ります

### `sbv2`

- 実際の TTS 推論サーバーです
- ポート `5000` で待ち受けます
- `.env` の `SBV2_DEVICE` を見て `cpu` または `cuda` で動作します

## 4. `.env` で設定する項目

編集対象は `.env` です。

### CPU で動かす場合

```env
SBV2_DEVICE=cpu
```

### GPU で動かす場合

```env
SBV2_DEVICE=cuda
```

補足:
- `cuda` にしても Docker 側で GPU が見えていなければ GPU 動作にはなりません
- `AMICA_OLLAMA_MODEL` は会話モデル設定であり、SBV2 の CPU/GPU 切替とは無関係です

## 5. 初回セットアップ手順

### スクリプトを使う場合

```powershell
.\scripts\dev-up-container-sbv2.ps1 -Build
```

このスクリプトは以下を起動対象にします。
- `amica`
- `injection-tool`
- `mcp-server`
- `sbv2`

`sbv2` は `sbv2-init` の成功に依存するため、初回は実質的に `sbv2-init` も通ります。

### 素の Compose で行う場合

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build sbv2
```

## 6. CPU / CUDA 切替手順

1. `.env` の `SBV2_DEVICE` を変更する
2. SBV2 を停止する
3. SBV2 を再起動する
4. ログと疎通を確認する

### スクリプト運用の推奨手順

```powershell
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1 -Build
```

2回目以降で build が不要なら通常は以下で足ります。

```powershell
.\scripts\dev-up-container-sbv2.ps1
```

### Compose だけで行う場合

```powershell
docker compose stop sbv2
docker compose up -d --build sbv2
```

## 7. 起動確認

### 7-1. 既定サービスに SBV2 が含まれているか

```powershell
docker compose config --services
```

期待値:
- `sbv2-init`
- `sbv2`

### 7-2. コンテナ状態

```powershell
docker ps --format "table {{.Names}}`t{{.Status}}"
```

少なくとも以下が確認対象です。
- `ark-sbv2-init`
- `ark-sbv2`

### 7-3. 初期化ログ

```powershell
docker logs ark-sbv2-init --tail 200
```

見るポイント:
- 初回モデル準備が完了しているか
- Hugging Face 取得失敗や権限エラーが出ていないか

### 7-4. SBV2 本体ログ

```powershell
docker logs ark-sbv2 --tail 200
```

見るポイント:
- 起動時例外がないか
- `SBV2_DEVICE` と矛盾する CUDA エラーがないか

### 7-5. HTTP 疎通確認

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

期待値:
- `StatusCode: 200`

### 7-6. Amica コンテナの接続先確認

```powershell
docker inspect ark-amica --format "{{range .Config.Env}}{{println .}}{{end}}" | findstr STYLEBERTVITS2
```

期待値:
- `NEXT_PUBLIC_STYLEBERTVITS2_SERVER_URL=http://sbv2:5000`
- `STYLEBERTVITS2_URL=http://sbv2:5000`

注意:
- 既定 `.env` で `AMICA_TTS_BACKEND=piper` の場合、Amica の通常発話は Piper を使います
- SBV2 切替確認はまず `ark-sbv2` のログと `http://127.0.0.1:5000/docs` で行ってください

## 8. GPU 利用確認

### 8-1. ホスト側の GPU 確認

```powershell
nvidia-smi
```

### 8-2. ホスト Python 環境での CUDA 確認

```powershell
D:\sbv2\Style-Bert-VITS2\venv\Scripts\python.exe -c "import torch; print('cuda_available=', torch.cuda.is_available()); print('device_count=', torch.cuda.device_count())"
```

期待値:
- `cuda_available= True`
- `device_count= 1` 以上

### 8-3. GPU 使用状況の監視

```powershell
nvidia-smi -l 1
```

見るポイント:
- TTS リクエスト時に GPU 使用率や VRAM 使用量が増えるか
- OOM が出るほど VRAM が逼迫していないか

## 9. よくあるトラブル

### `Models not found in model_assets`

原因候補:
- `sbv2-init` が失敗している
- `model_assets` に有効なモデルがない

確認:

```powershell
docker logs ark-sbv2-init --tail 200
```

### `/docs` は開くが音声合成できない

原因候補:
- 利用したいモデルの構成ファイルが足りない
- 独自モデルが `model_assets` 配下に正しく置かれていない

確認対象:
- `model_assets/<モデル名>/config.json`
- `model_assets/<モデル名>/style_vectors.npy`
- `model_assets/<モデル名>/*.safetensors`

### `SBV2_DEVICE=cuda` にしたのに GPU を使わない

原因候補:
- Docker が GPU を利用できる構成になっていない
- コンテナから CUDA が見えていない
- 実際には Amica が Piper を使っていて SBV2 を呼んでいない

確認:
- `docker logs ark-sbv2 --tail 200`
- `nvidia-smi`
- `http://127.0.0.1:5000/docs`
- `.env` の `AMICA_TTS_BACKEND`

### `docker compose up` で SBV2 が起動しない

確認:
- `docker compose config --services` に `sbv2-init` と `sbv2` が含まれているか
- `..\sbv2\Style-Bert-VITS2` が存在するか
- build context が sibling repo 前提になっていることを見落としていないか

## 10. すぐ復旧したいときの最短コマンド

```powershell
.\scripts\dev-down-container-sbv2.ps1
.\scripts\dev-up-container-sbv2.ps1 -Build
docker logs ark-sbv2-init --tail 200
docker logs ark-sbv2 --tail 200
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:5000/docs
```

## 11. 関連ドキュメント

- `docs/05_SETUP_AND_DEPLOYMENT_JA.md`
- `docs/08_RUNTIME_OPERATIONS_JA.md`
- `docs/09_TROUBLESHOOTING_JA.md`
- `docs/10_CONFIGURATION_REFERENCE_JA.md`
- `docs/16_MODEL_SWITCH_MANUAL_JA.md`
