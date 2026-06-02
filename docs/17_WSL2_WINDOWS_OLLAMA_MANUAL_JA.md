# WSL2 導入手順書 Windows 版 Ollama 併用

この文書は、Windows にインストールした Ollama.exe を使いながら、Ark-i の他サービスを WSL2 上で動かしたい場合の導入手順です。

前提:
- `ark-injection-ai-system` の現行構成を大きく変えずに使う
- Ollama だけは Windows 側で常駐させる
- Amica / injection-tool / MCP / TTS / DB は WSL2 上の Docker Engine または Docker Compose で動かす

この方式は可能ですが、完全 WSL2 構成よりもネットワーク前提が増えます。導入先へ渡す手順としては、まずこの文書の「制約」を理解したうえで採用可否を決めてください。

## 1. この構成が向いているケース

- Ollama は既に Windows サービスとして運用している
- GPU ドライバや Ollama モデル管理を Windows 側に寄せたい
- Docker Desktop のライセンスは避けたいが、LLM 本体までは Linux 側へ移したくない

向いていないケース:
- 導入先の説明をできるだけ単純にしたい
- Windows Firewall や WSL2 ネットワークの説明を避けたい
- 導入後の保守担当が Windows と WSL2 の境界を意識したくない

## 2. 現行構成の注意点

現行の ark-injection-ai-system は、主に Docker Desktop を前提にした `host.docker.internal` ベースの Ollama 参照になっています。

重要な前提:
- `AMICA_OLLAMA_URL`
- `AMICA_VISION_OLLAMA_URL`
- compose 内の `INJECTION_OLLAMA_URL`

このため、WSL2 上の Docker から Windows 側 Ollama にどう到達するかを、導入先ごとに確認する必要があります。

補足:
- この文書は「まず手順を整理する」ためのものです
- 現時点では ark-injection-ai-system の compose やスクリプト自体は変更しません
- 導入先で完全自動化したい場合は、後述の完全 WSL2 版のほうが整理しやすいです

## 3. 事前に決めること

導入前に次の 3 点を決めてください。

1. Ollama.exe は Windows ログイン後に自動起動させるか
2. Windows 側 Ollama API を WSL2 から参照できるようにするか
3. Ark-i のリポジトリ群は WSL2 の Linux filesystem に置くか

推奨:
- Ollama モデル本体は Windows 側の高速 SSD に置く
- Ark-i 一式は WSL2 の Linux filesystem に置く
- WSL2 から Windows 側 Ollama API の疎通確認を毎回できるようにする

## 4. 推奨配置

WSL2 側の例:

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

理由:
- 現行 compose は sibling repo を相対パスで参照します
- WSL2 の Linux filesystem に置いたほうが bind mount の性能が安定します
- `/mnt/c` や `/mnt/d` 配下に置くと、ファイル監視や npm install が重くなりやすいです

## 5. Windows 側の準備

### 5-1. Ollama をインストールする

Windows に Ollama.exe を導入し、通常どおり起動します。

確認例:

```powershell
ollama list
ollama ps
```

最低限用意したいモデル例:

- 会話用: `qwen3.5:9b` または `qwen2.5:7b`
- Vision 用: `llava`

例:

```powershell
ollama pull qwen3.5:9b
ollama pull llava
```

### 5-2. Windows 側で API が応答することを確認する

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:11434/api/tags
```

### 5-3. WSL2 から見える形で公開する

ここがこの構成の一番重要な点です。

確認事項:
- Ollama が `127.0.0.1` だけでなく WSL2 側から届く経路で待ち受けること
- Windows Firewall が `11434` を遮断しないこと
- WSL2 から `http://<Windows 側到達先>:11434` へ疎通できること

導入先によっては、Windows 側の listen 設定や firewall 設定の調整が必要です。

## 6. WSL2 側の準備

推奨ディストリビューション:
- Ubuntu 22.04 以降

必要ソフト:
- Git
- Docker Engine
- docker compose plugin
- curl

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

`unknown shorthand flag: 'f' in -f` のように表示される場合は、`docker compose` サブコマンドが使えておらず、compose plugin が未導入です。

対処方針:
- まず `docker compose version` が通る状態にする
- 一時的に `docker-compose version` が通る環境なら、検証中だけ `docker-compose -f ...` を使ってもよい
- 今後の手順書どおりに進めるには compose plugin の導入を優先する

例:

```bash
sudo apt update
sudo apt install -y git curl ca-certificates
```

Docker Engine と compose plugin の導入は、導入先の社内標準に合わせてください。

## 7. リポジトリ配置

bootstrap スクリプトを使う場合:

```bash
git clone https://github.com/nftdrive01-maker/ark-injection-ai-system.git
cd ark-injection-ai-system
bash ./scripts/setup-workspace.sh -ChatBackend ollama
```

Google Workspace MCP と e-Stat MCP をまだ使わない場合:

```bash
bash ./scripts/setup-workspace.sh -ChatBackend ollama -SkipGoogleWorkspaceMcp -SkipEstatMcp
```

注意:
- bash では `./scripts/setup-workspace.ps1` や `.\scripts\setup-workspace.ps1` はそのまま実行できません
- WSL では `bash ./scripts/setup-workspace.sh` を使ってください
- `setup-workspace.sh` はネイティブな bash 実装なので、PowerShell 7 は不要です

手動で clone する場合は次のとおりです。

WSL2 側で次のように clone します。

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

## 8. `.env` の作成

WSL2 側で `ark-injection-ai-system/.env.example` を `ark-injection-ai-system/.env` にコピーします。

```bash
cd ~/workspace/ark-injection-ai-system
cp .env.example .env
```

主要設定:

- `AMICA_CHATBOT_BACKEND=ollama`
- `AMICA_OLLAMA_MODEL=qwen3.5:9b`
- `AMICA_VISION_BACKEND=vision_ollama`
- `AMICA_VISION_OLLAMA_MODEL=llava`
- `AMICA_TTS_BACKEND=piper`

ここで重要なのは URL です。

設定方針:
- `AMICA_OLLAMA_URL` は WSL2 から見た Windows 側 Ollama API の URL にする
- `AMICA_VISION_OLLAMA_URL` も同じ URL に揃える
- `INJECTION_OLLAMA_URL` も同じ到達先に揃える
- 導入先で到達先が固定できるまで `host.docker.internal` を前提にしない

まず、WSL2 から見た Windows 側の到達先 IP を確認します。

```bash
HOST_IP=$(ip route | awk '/default/ {print $3}')
echo "$HOST_IP"
curl "http://$HOST_IP:11434/api/tags"
```

期待値:
- `echo` で Windows 側到達先 IP が表示される
- `curl` で Ollama の tags API が JSON を返す

`curl` が通ったら、その IP を以下の URL に使います。

例:

```env
AMICA_CHATBOT_BACKEND=ollama
AMICA_OLLAMA_URL=http://<windows-host-reachable-address>:11434
INJECTION_OLLAMA_URL=http://<windows-host-reachable-address>:11434
AMICA_OLLAMA_MODEL=qwen3.5:9b
AMICA_VISION_BACKEND=vision_ollama
AMICA_VISION_OLLAMA_URL=http://<windows-host-reachable-address>:11434
AMICA_VISION_OLLAMA_MODEL=llava
AMICA_TTS_BACKEND=piper
```

補足:
- `INJECTION_OLLAMA_URL` を設定すれば、injection-tool も同じ Windows 側 Ollama API を参照できます
- それでも疎通しない場合は Windows Firewall と listen address を確認してください

## 9. 起動手順

Windows 側:

1. Ollama.exe を起動する
2. `ollama list` で対象モデルが存在することを確認する

WSL2 側:

```bash
cd ~/workspace/ark-injection-ai-system
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

もし `docker compose` が使えず、`docker-compose version` は通る場合の暫定代替:

```bash
cd ~/workspace/ark-injection-ai-system
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

optional MCP も起動したい場合:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile google-workspace-mcp --profile estat-mcp up -d --build
```

## 10. 動作確認

### 10-1. WSL2 から Windows 側 Ollama API へ疎通確認

```bash
curl http://<windows-host-reachable-address>:11434/api/tags
```

### 10-2. コンテナ状態確認

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

### 10-3. Amica / injection-tool

- `http://localhost:3000`
- `http://localhost:4001`

### 10-4. Amica ログ

```bash
docker logs ark-amica --tail 200
```

### 10-5. injection-tool ログ

```bash
docker logs ark-injection-tool --tail 200
```

Ollama 接続で失敗する場合は、まず URL と firewall を疑ってください。

## 11. 既知の制約

- Windows 側 Ollama と WSL2 側コンテナの間でネットワーク境界がある
- 導入先によって Windows 側到達先アドレスが変わることがある
- `host.docker.internal` は Docker Desktop ほど素直には期待できない
- Windows Firewall の設定確認が必要になる
- 問題発生時に、Windows / WSL2 / Docker bridge のどこで詰まっているか切り分けが必要になる

## 12. この方式を選ぶ判断基準

この方式を選んでよい条件:
- 導入先に Windows 管理者権限がある
- Ollama.exe の保守を Windows 側で続けたい
- WSL2 から Windows API への疎通確認を運用に組み込める

完全 WSL2 版を選んだほうがよい条件:
- 導入先の構成説明を簡単にしたい
- Docker Desktop を完全に外したい
- 障害切り分けを Linux 側に寄せたい
- 将来的に自動化や IaC 化を進めたい