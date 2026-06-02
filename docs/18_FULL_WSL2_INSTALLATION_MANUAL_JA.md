# 完全 WSL2 導入手順書

この文書は、Ark-i の構成要素をできるだけ WSL2 側へ寄せて導入したい場合の手順書です。

対象:
- Docker Desktop を使わずに導入したい人
- Ark-i の主要サービスを WSL2 の Linux 側で統一的に扱いたい人
- Windows と Linux の境界をまたぐ運用を減らしたい人

この方式では、リポジトリ配置、Docker 実行、運用手順を WSL2 側へ寄せます。Windows 側はターミナル、ブラウザ、必要に応じた GPU ドライバの提供に留める前提です。

## 1. この構成が向いているケース

- Docker Desktop ライセンスを避けたい
- 導入先へ Linux ベースの説明で統一して渡したい
- WSL2 内の Docker Engine を標準運用にしたい

向いていないケース:
- 既に Windows 側に Ollama や周辺ツール運用が固まっている
- Windows PowerShell スクリプト中心の現行導入フローをそのまま使いたい

## 2. 現行構成との関係

現行の ark-injection-ai-system は、Windows + Docker Desktop + PowerShell の導線が主です。

そのため、完全 WSL2 版では次を理解しておく必要があります。

- 既存の PowerShell スクリプトは補助資料として扱う
- 起動停止は `docker compose` コマンド主体で運用する
- repo は WSL2 側 Linux filesystem に配置する
- `host.docker.internal` 前提の設定は、そのままでは使わない場合がある

この文書は、現行リポジトリを大きく修正せずに「導入と運用の考え方」を整理するためのものです。

## 3. 推奨アーキテクチャ

推奨方針:
- Ark-i のリポジトリ群はすべて WSL2 側に置く
- Docker Engine は WSL2 側で動かす
- Ollama も WSL2 側で動かす
- ブラウザ操作は Windows 側から `localhost` へアクセスする

構成イメージ:

```text
Windows
  ├─ Browser
  └─ VS Code

WSL2 Ubuntu
  ├─ Docker Engine
  ├─ Ollama
  ├─ ark-injection-ai-system
  ├─ amica
  ├─ injection-tool
  ├─ mcp-server
  ├─ sbv2/Style-Bert-VITS2
  ├─ google-workspace-mcp
  ├─ estat-mcp
  └─ piper
```

## 4. WSL2 側の準備

推奨:
- Ubuntu 22.04 以降
- 十分なディスク空き容量
- 可能なら高速 SSD

必要ソフト:
- Git
- Docker Engine
- docker compose plugin
- curl
- Python や build 周辺ツールは必要時に追加

Ubuntu 22.04 以降で Docker Engine と compose plugin を直接入れる例:

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Docker を sudo なしで使いたい場合:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Docker デーモン起動例:

```bash
sudo service docker start
```

systemd を有効にしている WSL なら次でも構いません。

```bash
sudo systemctl enable --now docker
```

確認コマンド:

```bash
docker version
docker compose version
```

`docker compose` で `unknown shorthand flag: 'f' in -f` が出る場合は、compose plugin が未導入です。

例:

```bash
sudo apt update
sudo apt install -y git curl ca-certificates
```

Docker Engine と compose plugin は、導入先標準に合わせてインストールしてください。

## 5. リポジトリ配置

WSL2 側で次のように並列配置します。

```text
~/workspace/
  ark-injection-ai-system/
  amica/
  injection-tool/
  mcp-server/
  sbv2/Style-Bert-VITS2/
  google-workspace-mcp/
  estat-mcp/
  piper/
```

clone 例:

```bash
mkdir -p ~/workspace
cd ~/workspace

git clone <ark-injection-ai-system の URL>
git clone <amica の URL>
git clone <injection-tool の URL>
git clone <mcp-server の URL>
git clone <google-workspace-mcp の URL>
git clone <estat-mcp の URL>
mkdir -p sbv2
git clone <Style-Bert-VITS2 の URL> sbv2/Style-Bert-VITS2
git clone <piper の URL>
```

## 6. Ollama の導入

完全 WSL2 版では、Ollama も Linux 側に置くことを推奨します。

手順の考え方:

1. WSL2 内に Ollama を導入する
2. WSL2 内で Ollama サービスを起動する
3. WSL2 内から `http://127.0.0.1:11434` で応答することを確認する
4. 必要モデルを pull する

例:

```bash
ollama pull qwen3.5:9b
ollama pull llava
ollama list
```

## 7. `.env` の作成

`ark-injection-ai-system/.env.example` をコピーして `.env` を作ります。

```bash
cd ~/workspace/ark-injection-ai-system
cp .env.example .env
```

最初の推奨値:

```env
AMICA_CHATBOT_BACKEND=ollama
AMICA_OLLAMA_URL=http://host.docker.internal:11434
AMICA_OLLAMA_MODEL=qwen3.5:9b
AMICA_VISION_BACKEND=vision_ollama
AMICA_VISION_OLLAMA_URL=http://host.docker.internal:11434
AMICA_VISION_OLLAMA_MODEL=llava
AMICA_TTS_BACKEND=piper
SBV2_DEVICE=cpu
PIPER_DEVICE=cpu
```

注意:
- 現行リポジトリは Docker Desktop 前提の URL 例が残っています
- 完全 WSL2 版でそのまま使えるとは限りません
- 導入先では「Docker コンテナから見た Ollama URL」に必ず読み替えてください

実務上の考え方:
- Ollama をコンテナ外の WSL2 サービスとして動かす場合、各コンテナからその URL に到達できる必要があります
- 導入先で URL 設計を固定できるまで、起動前に必ず疎通確認してください

## 8. 起動手順

基本スタック起動:

```bash
cd ~/workspace/ark-injection-ai-system
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

optional MCP も含める場合:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile google-workspace-mcp --profile estat-mcp up -d --build
```

停止:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

## 9. 動作確認

### 9-1. Ollama 応答確認

WSL2 側で:

```bash
curl http://127.0.0.1:11434/api/tags
```

### 9-2. コンテナ確認

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### 9-3. UI アクセス

- `http://localhost:3000`
- `http://localhost:4001`

### 9-4. ログ確認

```bash
docker logs ark-amica --tail 200
docker logs ark-injection-tool --tail 200
docker logs ark-sbv2 --tail 200
docker logs ark-piper --tail 200
```

## 10. 運用上の注意

- repo は `/mnt/c` や `/mnt/d` ではなく WSL2 側に置いたほうが安定します
- 開発時は polling ベースのファイル監視が入るため、CPU 使用率が上がることがあります
- qwen3.5:9b と vision モデルを同居させる場合、メモリとストレージに余裕が必要です
- CPU 運用でも試せますが、速度はかなり落ちる可能性があります

## 11. 既知の課題

- 現行の `.env.example` や README は Windows + Docker Desktop 例が中心です
- 現行の PowerShell スクリプトをそのまま主導線にはしづらいです
- Ollama 接続 URL まわりは、導入先の WSL2 ネットワーク条件に合わせた読み替えが必要です
- 完全 WSL2 を正式サポートにしたい場合は、将来的に Linux 向け手順の一元化や compose の環境変数整理が望まれます

## 12. この方式を選ぶ判断基準

この方式を選んでよい条件:
- Docker Desktop を使わずに運用したい
- Linux ベースの手順で導入先へ説明したい
- WSL2 内に Ark-i の依存を寄せても問題ない

Windows 版 Ollama 併用を選んだほうがよい条件:
- Ollama モデルや GPU 周りは Windows 側で維持したい
- まずは最小変更で導入したい
- Linux 側へ移す範囲を限定したい