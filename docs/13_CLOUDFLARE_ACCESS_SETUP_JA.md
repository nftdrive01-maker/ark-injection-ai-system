# injection-tool 4001 Cloudflare Access 設定手順

作成日: 2026-05-25

## 目的

この手順書は、injection-tool の 4001 管理画面を Cloudflare Tunnel + Cloudflare Access で安全に外部公開するための設定手順をまとめたものです。

前提:

- injection-tool 側の管理認証 hardening が適用済みであること
- `INJECTION_ADMIN_USERNAME` / `INJECTION_ADMIN_PASSWORD` / `INJECTION_SESSION_SECRET` が設定済みであること
- `docker-compose.yml` で 4001 が localhost 束縛になっていること

## 構成方針

- Tunnel の転送先: `http://127.0.0.1:4001`
- Cloudflare Access: 管理 URL に必須
- injection-tool 側: Cloudflare Access 通過後も `/login` で管理認証を要求

つまり、認証は以下の二段構えになります。

1. Cloudflare Access で入口制御
2. injection-tool の管理ログインでアプリ内制御

## 手順 1: 事前確認

以下をローカルで確認します。

```powershell
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

`ark-injection-tool` が `127.0.0.1:4001->4001/tcp` になっていることを確認してください。

未認証時の保護確認:

```powershell
Invoke-WebRequest -Uri http://localhost:4001/admin -MaximumRedirection 0 -UseBasicParsing
```

期待値:

- `/login` への redirect になる

## 手順 2: Cloudflare Tunnel を用意する

### 一時公開で試す場合

```powershell
cloudflared tunnel --url http://127.0.0.1:4001
```

表示された `https://xxxx.trycloudflare.com` をブラウザで開くと、そのまま injection-tool の login 画面に到達します。

補足:

- 一時 URL は再起動で変わります
- 継続運用では次の Named Tunnel を使ってください

### 本番運用で推奨する形

Named Tunnel を作成し、管理用 hostname を 4001 へ向けます。

概念上の設定例:

- hostname: `admin.example.com`
- service: `http://127.0.0.1:4001`

補足:

- 3000 のフロントアプリ公開用 hostname と 4001 の管理用 hostname は分けてください
- 4001 は管理用途なので、利用者向け URL と混在させないでください

### Named Tunnel を Cloudflare ダッシュボードで作る手順

1. ブラウザで Cloudflare ダッシュボードを開く
2. 左メニューで Zero Trust を開く
3. Zero Trust の左メニューで Networks を開く
4. Tunnels を開く
5. Create a tunnel をクリックする
6. Tunnel type で Cloudflared を選ぶ
7. Next をクリックする
8. Tunnel name に `injection-tool-admin` など管理用とわかる名前を入れる
9. Save tunnel をクリックする
10. Connector setup 画面で、自分の環境に合う OS を選ぶ
11. 表示された `cloudflared service install ...` 形式または token 付きコマンドをホスト PC で実行する

PowerShell 例:

```powershell
cloudflared service install <Cloudflareが表示したトークン>
```

12. コマンド実行後、ダッシュボードへ戻る
13. Connector が Healthy になったことを確認する

### Public Hostname を追加する手順

1. 作成した tunnel の詳細画面を開く
2. Public Hostnames タブを開く
3. Add a public hostname をクリックする
4. Subdomain に `admin` を入力する
5. Domain で利用するドメインを選ぶ
6. Path は空欄のままにする
7. Service Type は HTTP を選ぶ
8. URL に `localhost:4001` または `127.0.0.1:4001` を入力する
9. Additional application settings は必要がなければ既定のままにする
10. Save hostname をクリックする

確認ポイント:

- 3000 用とは別 hostname にする
- service が `localhost:4001` を向いている
- 誤って `localhost:3000` を設定していない

## 手順 3: Cloudflare Access Application を作成する

Cloudflare Zero Trust ダッシュボードで以下を設定します。

1. Zero Trust 左メニューで Access を開く
2. Applications を開く
3. Add an application をクリックする
4. Self-hosted を選択する
5. Select をクリックする

設定例:

- Application name: `injection-tool-admin`
- Domain: `admin.example.com`
- Session duration: 短めに設定

### 画面入力の具体例

1. Application name に `injection-tool-admin` を入力する
2. Subdomain に `admin` を入力する
3. Domain に自分のドメインを選ぶ
4. Session Duration は短めに設定する
  例: `1 hour` または `8 hours`
5. App launcher visibility は通常 Hidden でよい
6. Browser rendering / CORS / Cookie settings は特段必要がなければ既定のままにする
7. Next をクリックする

## 手順 4: Access Policy を設定する

最低限、以下を守ってください。

- `Allow Everyone` にしない
- 許可対象はメール、グループ、IdP 属性で絞る
- 管理担当者だけに限定する

推奨例:

- Rule action: `Allow`
- Include:
  - Email ends with `@your-company.example`
  - または特定メールアドレス
  - または特定 IdP group
- 必要なら Require:
  - One-time PIN 以外の IdP 認証
  - MFA

さらに絞る場合:

- 国制限
- IP 制限
- デバイスポスチャ

### ポリシー作成のクリック手順

1. Policy name に `admin-allow-company-users` などの名前を入れる
2. Action は Allow を選ぶ
3. Rules セクションの Include を設定する
4. Add include をクリックする
5. 許可方式を選ぶ

よく使う選択肢:

- Emails ending in
- Emails
- Groups

例 1: 会社メールドメインで絞る場合

1. Include で Emails ending in を選ぶ
2. 値に `your-company.example` を入れる

例 2: 特定ユーザーだけ許可する場合

1. Include で Emails を選ぶ
2. 許可したいメールアドレスを追加する

例 3: IdP のグループで絞る場合

1. Include で Groups を選ぶ
2. IdP 側のグループを選ぶ

Require を使う場合:

1. Add require をクリックする
2. MFA または特定認証条件を選ぶ

避ける設定:

- Include に Everyone を入れる
- 一時検証のまま広い許可条件を残す

最後に:

1. Add policy をクリックする
2. Application の保存画面で Save application をクリックする

## 手順 5: 動作確認

ブラウザで管理用 hostname を開きます。

期待する流れ:

1. まず Cloudflare Access の認証画面が出る
2. 認証通過後に injection-tool の `/login` が表示される
3. 管理 credentials でログインすると `/admin` が開く

### 動作確認の実施手順

1. 普段使っていないシークレットウィンドウを開く
2. `https://admin.example.com` を開く
3. Cloudflare Access の認証画面が出ることを確認する
4. 許可対象のアカウントで認証する
5. 認証後に injection-tool の login 画面へ移ることを確認する
6. `INJECTION_ADMIN_USERNAME` と `INJECTION_ADMIN_PASSWORD` でログインする
7. `/admin` が表示されることを確認する
8. ログアウトする
9. 再度 `/admin` を開いて login へ戻ることを確認する

## 手順 6: cookie の確認

Access の背後で login した後、ブラウザ開発者ツールで cookie を確認します。

期待値:

- `injection_session`
- `HttpOnly`
- `Secure`
- `SameSite=Lax`

この構成では `x-forwarded-proto: https` を見て Secure cookie が付くように実装済みです。

### ブラウザでの確認手順

1. 管理画面へログインした状態で F12 を押す
2. Application タブを開く
3. Storage の Cookies を開く
4. `https://admin.example.com` を選ぶ
5. `injection_session` を選ぶ
6. 以下を確認する

- Name が `injection_session`
- HttpOnly が有効
- Secure が有効
- SameSite が `Lax`

## 手順 7: 運用ルール

- Cloudflare Access を外して 4001 を直接公開しない
- アプリ側の `/login` 認証も残す
- 管理 credentials を他サービスと使い回さない
- session secret を安全に保管する
- 管理担当者の変更時は Access 側の許可対象も更新する

## よくある誤り

### 1. 3000 と 4001 を同じ hostname で扱う

避けてください。利用者向け公開と管理公開は分離してください。

### 2. Access を付けたのでアプリ側 login は不要と判断する

避けてください。入口認証とアプリ内認証は両方必要です。

### 3. Tunnel の転送先を `http://0.0.0.0:4001` にする

避けてください。`http://127.0.0.1:4001` または `http://localhost:4001` を使ってください。

### 4. `.env` の管理認証値を空のまま起動する

現行実装では fail-closed になります。必須値を設定してください。

### 5. Access Application は作ったが Policy を保存していない

Application 作成だけでは保護は成立しません。Allow policy を保存しているか確認してください。

### 6. hostname は作ったが Tunnel 側の Public Hostname が 4001 を向いていない

Application と Tunnel の両方が必要です。Access だけ、Tunnel だけでは不十分です。

## 作業後の最終確認

以下が全部 Yes なら、設定は一通り完了です。

- `https://admin.example.com` で Cloudflare Access が出る
- Access 通過後に injection-tool login が出る
- 管理ログイン後に `/admin` が開く
- cookie が `Secure` / `HttpOnly` / `SameSite=Lax`
- `docker ps` で `ark-injection-tool` が `127.0.0.1:4001->4001/tcp` になっている

## 関連資料

- `docs/11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md`
- `docs/12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md`
- `ark-injection-ai-system/EXTERNAL_PUBLISH_MANUAL_JA.md`