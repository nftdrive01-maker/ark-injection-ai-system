# 外部公開手順マニュアル

このシステム（ark-injection-ai-system）を外部ネットワークから利用可能にする手順を説明します。  
外部公開の方法は **2 種類** あります。用途に合わせて選択してください。

---

## 方式比較

| 方式 | 対象 | HTTPS | 独自ドメイン | 手軽さ |
|---|---|---|---|---|
| **A: Cloudflare Tunnel** | インターネット公開・デモ | ✅ 自動 | △ 無料サブドメイン | ⭐⭐⭐ |
| **B: LAN HTTPS (Caddy)** | 社内LAN・ローカルネットワーク | ✅ 自己署名 | ✗ IPアドレス/amica.local | ⭐⭐ |

---

## 方式 A: Cloudflare Tunnel（インターネット公開）

> 補足:
> - フロントアプリ (:3000) の公開が基本です。
> - injection-tool 管理画面 (:4001) を外部公開する場合は、Cloudflare Access を必須にしてください。
> - 管理画面公開時は docs/11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md、docs/12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md、docs/13_CLOUDFLARE_ACCESS_SETUP_JA.md を併読してください。

### 前提条件

- Docker Desktop が起動していること
- インターネット接続があること
- `cloudflared` コマンドが使えること（下記でインストール）

### 手順

#### 1. cloudflared のインストール

```powershell
winget install Cloudflare.cloudflared
```

インストール後、ターミナルを再起動してください。

#### 2. システムを起動する

```powershell
cd D:\ark-injection-ai-system
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

フロントアプリが `http://localhost:3000` で起動していることを確認してください。

#### 3. Cloudflare Tunnel を開始する（一時 URL）

```powershell
cloudflared tunnel --url http://localhost:3000
```

コマンド実行後、以下のような URL が表示されます：

```
+--------------------------------------------------------------------------------------------+
|  Your quick Tunnel has been created! Visit it at (it may take some time to be reachable):  |
|  https://xxxx-yyyy-zzzz.trycloudflare.com                                                  |
+--------------------------------------------------------------------------------------------+
```

この URL をメモしてください。

#### 4. 外部 URL を環境変数に設定する

`.env` ファイルを開き、`CLOUDFLARE_EXTERNAL_URL` のコメントアウトを外して URL を設定します：

```env
CLOUDFLARE_EXTERNAL_URL=https://xxxx-yyyy-zzzz.trycloudflare.com
```

#### 5. コンテナを再起動して設定を反映する

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate injection-tool google-workspace-mcp
```

#### 6. Google OAuth リダイレクト URI を更新する（Google 連携を使う場合）

Google Cloud Console で OAuth クライアントの「承認済みリダイレクト URI」に以下を追加します：

```
https://xxxx-yyyy-zzzz.trycloudflare.com/oauth/callback
```

> **注意**: Cloudflare の無料トンネルは再起動するたびに URL が変わります。  
> 固定 URL が必要な場合は Cloudflare Zero Trust の Named Tunnel を使用してください。

#### 7. 動作確認

ブラウザで Cloudflare の URL を開いてフロントアプリが表示されることを確認してください。

---

## 方式 B: LAN HTTPS（社内ネットワーク公開）

LAN 内の他の端末からブラウザでアクセスできるようにします。  
自己署名証明書を使い HTTPS で提供します。

### 前提条件

- `mkcert` がインストールされていること（下記でインストール）
- Docker Desktop が起動していること

### 手順

#### 1. mkcert のインストール

```powershell
winget install FiloSottile.mkcert
mkcert -install
```

インストール後、ターミナルを再起動してください。

#### 2. 証明書を生成する

```powershell
cd D:\ark-injection-ai-system
.\scripts\setup-lan-https.ps1
```

ホストの LAN IP アドレスを自動検出し、`.certs/` フォルダに証明書を生成します。

#### 3. システムを起動する

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

#### 4. HTTPS リバースプロキシ（Caddy）を追加起動する

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.lan-https.yml up -d amica-https
```

#### 5. アクセス URL の確認

ホストの IP アドレスを確認します：

```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } | Select-Object IPAddress
```

LAN 内の端末から以下の URL でアクセスできます：

```
https://<ホストのIPアドレス>/
https://amica.local/     # hosts ファイル設定が必要
```

#### 6. 接続端末への証明書インストール（初回のみ）

LAN 内の端末で「証明書エラー」が表示される場合、接続元端末に `mkcert` ルート証明書をインストールしてください。

接続元端末（Windows）での操作：

```powershell
# ホスト PC から rootCA.pem を取得してインストール
mkcert -CAROOT   # CA ファイルの場所を確認
```

取得した `rootCA.pem` を接続元端末の「信頼されたルート証明機関」にインポートします。

---

## 注意事項

### セキュリティ

- 外部公開時は `.env` の以下の値を**必ず変更**してください：
  - `DB_PASSWORD` （デフォルト `password` のまま使わない）
  - `GOOGLE_OAUTH_CLIENT_ID` / `GOOGLE_OAUTH_CLIENT_SECRET` （自分のクレデンシャルを使う）
- DBHub（:8080）・injection-tool（:4001）・MCP サーバー群のポートは外部に公開しないでください。  
  すべての外部アクセスはフロントアプリの BFF プロキシ経由で行われます。
- Cloudflare Tunnel はフロントアプリの **:3000 ポートのみ** をトンネルします。

#### injection-tool 管理画面 (:4001) を公開したい場合

- 現在の実装では、4001 は localhost 束縛とアプリ側管理認証を前提に hardening 済みです
- それでも 4001 公開時は Cloudflare Access を前段に置いてください
- Tunnel の公開先は `http://127.0.0.1:4001` または `http://localhost:4001` を使ってください
- Access 通過後も、injection-tool 側の `/login` による管理ログインを残してください
- 手順書: `docs/13_CLOUDFLARE_ACCESS_SETUP_JA.md`（クリック手順レベル）
- 事前チェック: `docs/12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md`

### 停止手順

#### Cloudflare Tunnel の停止

`cloudflared` を実行しているターミナルで `Ctrl+C` を押します。  
停止後は `.env` の `CLOUDFLARE_EXTERNAL_URL` を再度コメントアウトし、コンテナを再起動してください：

```powershell
# CLOUDFLARE_EXTERNAL_URL をコメントアウト後
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --force-recreate injection-tool google-workspace-mcp
```

#### LAN HTTPS の停止

```powershell
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.lan-https.yml down
```

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| Cloudflare URL を開いても応答がない | フロントアプリのコンテナが未起動 | `docker compose up -d` を実行 |
| Google 認証の callback エラー | `CLOUDFLARE_EXTERNAL_URL` 未設定またはリダイレクト URI 未登録 | 手順 4・6 を確認 |
| LAN 端末で「証明書エラー」 | mkcert ルート CA が未インストール | 接続元端末に rootCA をインストール |
| DBHub にアクセスできない | `database` コンテナの起動待ち | `docker compose up -d database dbhub` を再実行 |
| `cloudflared` が見つからない | インストール後ターミナル未再起動 | ターミナルを再起動 |
