# WSL2 ネイティブ Docker 導入チェックリスト

このチェックリストは、Docker Desktop を使わずに WSL2 内へ Docker Engine と docker compose plugin を直接入れるときの最短確認用です。

対象:
- WSL2 上で Ark-i を動かしたい人
- Docker Desktop は使わない方針の人
- Windows 側に Ollama.exe を残すか、WSL 側に Ollama を置くかを切り替えながら確認したい人

## 1. 前提確認

- Ubuntu 22.04 以降を使っている
- repo は WSL2 の Linux filesystem に置いている
- `docker` コマンドを WSL2 内で使う前提である

確認:

```bash
pwd
uname -a
ps -p 1 -o comm=
```

見るポイント:
- 作業ディレクトリが `/home/...` 配下になっている
- PID 1 が `systemd` なら service 管理しやすい

## 2. Docker Engine と compose plugin の導入確認

```bash
docker version
docker compose version
```

期待値:
- `docker version` が Client / Server ともに表示される
- `docker compose version` が表示される

異常例:
- `docker: unknown command: docker compose`
- `unknown shorthand flag: 'f' in -f`

この場合:
- compose plugin 未導入の可能性が高い
- [17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md](./17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md) または [18_FULL_WSL2_INSTALLATION_MANUAL_JA.md](./18_FULL_WSL2_INSTALLATION_MANUAL_JA.md) の Docker 導入手順を先に実施する

## 3. docker.service の起動確認

```bash
sudo systemctl reset-failed docker.service docker.socket
sudo systemctl enable --now docker.socket
sudo systemctl start docker.service
sudo systemctl status docker.socket docker.service --no-pager -l
```

期待値:
- `docker.socket` が `active (running)`
- `docker.service` が `active (running)`

異常例:
- `failed to load listeners: no sockets found via socket activation`

この場合:
- `docker.socket` が有効になっていないことが多い
- `service docker start` より `systemctl enable --now docker.socket` を優先する

## 4. Workspace bootstrap 確認

```bash
bash ./scripts/setup-workspace.sh -ChatBackend chatgpt -SkipGoogleWorkspaceMcp -SkipEstatMcp
```

期待値:
- 関連 repo の clone が進む
- `.env` が生成される
- `ark-injection-ai-system.code-workspace` が生成される
- 最後に `Workspace bootstrap completed.` が出る

補足:
- WSL では `bash ./scripts/setup-workspace.sh` を使う
- `pwsh` は不要

## 5. Windows 側 Ollama.exe を使う場合の疎通確認

```bash
HOST_IP=$(ip route | awk '/default/ {print $3}')
echo "$HOST_IP"
curl "http://$HOST_IP:11434/api/tags"
```

期待値:
- `HOST_IP` が表示される
- `curl` が JSON を返す

この `HOST_IP` を以下へ反映する:
- `AMICA_OLLAMA_URL`
- `AMICA_VISION_OLLAMA_URL`
- `INJECTION_OLLAMA_URL`

## 6. `.env` の最低確認

```bash
grep -E 'AMICA_CHATBOT_BACKEND|AMICA_OLLAMA_URL|AMICA_VISION_OLLAMA_URL|INJECTION_OLLAMA_URL' .env
```

Windows 側 Ollama.exe を使う例:

```dotenv
AMICA_CHATBOT_BACKEND=ollama
AMICA_OLLAMA_URL=http://<host-ip>:11434
INJECTION_OLLAMA_URL=http://<host-ip>:11434
AMICA_VISION_OLLAMA_URL=http://<host-ip>:11434
```

## 7. Compose 起動確認

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --build
```

起動後の確認:

```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs ark-amica --tail 100
docker logs ark-injection-tool --tail 100
```

## 8. よくある詰まりどころ

### `docker compose` が使えない

- compose plugin 未導入
- `docker compose version` を先に確認する

### `failed to load listeners: no sockets found via socket activation`

- `docker.socket` が有効になっていない
- `systemctl enable --now docker.socket` を先に実行する

### `host.docker.internal` が通らない

- WSL ネイティブ Docker ではそのまま通る前提にしない
- `HOST_IP=$(ip route | awk '/default/ {print $3}')` で取得した IP を使う

### bootstrap は成功したのに起動しない

- bootstrap は clone / `.env` / `.code-workspace` 生成まで
- Docker Engine や compose plugin の導入は別途必要

## 9. 関連資料

- [17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md](./17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md)
- [18_FULL_WSL2_INSTALLATION_MANUAL_JA.md](./18_FULL_WSL2_INSTALLATION_MANUAL_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)