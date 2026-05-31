# injection-tool 4001 Cloudflare Access 公開チェックリスト

作成日: 2026-05-25

## 目的

このチェックリストは、injection-tool の 4001 管理画面を Cloudflare Tunnel + Cloudflare Access 前提で外部公開するときに、最低限確認すべき項目をまとめたものです。

## 公開前チェック

- `INJECTION_ADMIN_USERNAME` が設定されている
- `INJECTION_ADMIN_PASSWORD` が設定されている
- `INJECTION_SESSION_SECRET` が 32 文字以上の十分長いランダム値で設定されている
- `docker-compose.yml` の injection-tool 公開ポートが `127.0.0.1:${INJECTION_TOOL_PORT:-4001}:4001` になっている
- injection-tool の再作成または再起動を済ませている
- `http://localhost:4001/admin` に未認証でアクセスしたとき `/login` へリダイレクトされる
- 管理ログイン後に `http://localhost:4001/admin` が正常表示される

## Cloudflare Tunnel 設定チェック

- Cloudflare Tunnel の公開先が `http://127.0.0.1:4001` または `http://localhost:4001` を向いている
- 4001 を直接インターネットへ公開していない
- Access を付ける対象 hostname が管理用 URL だけになっている
- Tunnel の対象 URL を誤って 3000 側と混同していない

## Cloudflare Access 設定チェック

- Access Policy が有効になっている
- 許可対象のメールアドレス、グループ、または IdP 条件が最小限に絞られている
- `Everyone` や広すぎる許可条件になっていない
- セッション有効期限が長すぎない
- 管理画面用 hostname に対して Access が必須になっている
- 必要なら国・IP 制限も追加している

## 公開後の動作確認

- ブラウザで管理用 URL にアクセスすると、まず Cloudflare Access の認証が出る
- Access 通過後、injection-tool の `/login` が表示される
- 管理ログイン後に `/admin` が開く
- ログイン時のレスポンス cookie に `Secure` `HttpOnly` `SameSite=Lax` が付いている
- ログアウト後に再度 `/admin` へアクセスすると `/login` に戻る
- 別ブラウザまたは未認証セッションで管理 URL を開くと Access または login が要求される

## セキュリティ確認

- Cloudflare Access を通過しても、アプリ側の管理ログインが別で必要なことを確認する
- `.env` の管理 credentials と session secret をリポジトリ外で安全に保管している
- 管理 credentials を他用途で使い回していない
- session secret のローテーション手順を決めている
- ローカル端末自体のログイン保護、ディスク暗号化、OS 更新が維持されている

## 監視と運用

- Cloudflare Access の監査ログを確認できる状態にしている
- injection-tool コンテナログを確認できる状態にしている
- 不審なログイン失敗やアクセス元を定期確認する
- 管理者の退職・権限変更時に Access 側の許可対象も更新する

## 現時点の補足

- 現行構成では Cloudflare Access を前段に置くことで、防御はかなり強くなる
- ただし Access を使っても、アプリ側認証は外さない
- さらに強化するなら、管理ログインのレート制限を永続ストア化する