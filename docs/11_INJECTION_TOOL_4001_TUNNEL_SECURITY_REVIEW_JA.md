# injection-tool 4001 管理画面 トンネル公開セキュリティ調査レポート

作成日: 2026-05-25

## 結論

初回調査時点では、4001 の管理画面をトンネルで外向け公開することは安全ではありませんでした。

2026-05-25 の修正により、以下の重大事項は解消済みです。

- 管理認証の固定フォールバック secret を撤廃
- 管理資格情報または session secret 未設定時の fail-closed 化
- token 検証側でも unsafe 構成を拒否
- 4001 のホスト公開を `127.0.0.1` 束縛へ変更
- `x-forwarded-proto` を用いた Secure cookie 判定の追加

現時点の評価は「必須の環境変数が適切に管理される前提で、初回指摘時より安全に公開可能」です。ただし、ログイン試行制限の永続化不足など中程度の残課題は残っています。

## 調査対象

- injection-tool の管理認証実装
- middleware による管理画面・管理 API 保護
- Cloudflare Quick Tunnel 制御 API
- ark-injection-ai-system 側の docker compose / .env 構成
- 4001 を外向け公開した場合の実効リスク

## 確認できた防御策

- 管理画面の認証は HttpOnly cookie ベースへ移行済み
- 管理 API は middleware で保護され、管理系 `/api/*` には認証済み header を注入する構成
- 管理系の変更系リクエストは same-origin チェックを実施
- ログイン試行には IP 単位の簡易レート制限がある
- login API はデフォルトの `admin/admin` をそのまま受け入れない設計になっている
- `INJECTION_SESSION_SECRET` 未設定時の固定値フォールバックは撤廃済み
- token 検証は unsafe 構成を fail-closed で拒否する
- 4001 は `127.0.0.1` 束縛へ変更済み
- トンネル越し HTTPS は `x-forwarded-proto` で判定し Secure cookie を付与する

これにより、初回調査で指摘した Critical / High の主要論点は解消しました。残る論点は下記のとおりです。

## 指摘事項

### 1. Resolved: 固定フォールバック secret による管理セッション偽造リスク

**根拠**

- `src/lib/auth-shared.ts` で `INJECTION_SESSION_SECRET` の固定フォールバックを撤廃
- `src/lib/auth-shared.ts` で `INJECTION_ADMIN_USERNAME` / `INJECTION_ADMIN_PASSWORD` 未設定時は unsafe と判定
- `src/lib/auth.ts` と `src/lib/auth-edge.ts` のトークン検証は unsafe 構成時に false を返す
- `ark-injection-ai-system/.env` に必須の管理認証変数を設定済み

**影響**

unsafe 構成でも token 検証側が受け入れる問題は解消されました。現在は必須設定が欠けると login だけでなく token 検証も fail-closed になります。

**評価**

本件は解消済みです。

**必須対策**

- 設定済み credentials / secret を継続管理する
- secret のローテーション手順を別途整備する

### 2. Resolved: 4001 の 0.0.0.0 公開によるトンネル外到達面

**根拠**

- `ark-injection-ai-system/docker-compose.yml` は `"127.0.0.1:${INJECTION_TOOL_PORT:-4001}:4001"` へ変更済み

**影響**

localhost 束縛により、少なくとも compose 既定値ではトンネル外の広域到達面は大きく縮小しました。ホスト内ローカルプロセスからの到達は残るため、端末自体の保護は別途必要です。

**評価**

本件は主要な公開経路リスクとしては解消済みです。

**必須対策**

- localhost 束縛を維持する
- ホスト側ファイアウォールやローカル管理権限も適切に保護する

### 3. Low-Medium: Secure cookie 属性の転送プロトコル判定

**根拠**

- `src/app/api/auth/login/route.ts` と `src/middleware.ts` は `x-forwarded-proto` を優先して Secure 判定する
- localhost 束縛により、トンネル外の広域 HTTP 到達面は縮小している

**影響**

Cloudflare Tunnel のような TLS 終端プロキシ配下では Secure cookie を配布できるよう改善済みです。残る論点は、ホストローカル HTTP での運用時に Secure が付かないことですが、これは開発用途寄りの挙動です。

**評価**

主要リスクは低下しましたが、管理用途では HTTPS 経由を前提とすべきです。

**推奨対策**

- 本番運用ではトンネル経由 HTTPS を前提とする
- 必要なら Secure 強制フラグを将来追加する

### 4. Medium: ログイン試行制限はメモリ内のみで、再起動や多重起動に弱い

**根拠**

- `src/app/api/auth/login/route.ts` のレート制限は process 内 `Map` ベース

**影響**

コンテナ再起動で即リセットされます。将来プロセス多重化や複数インスタンス化した場合も整合しません。単体コンテナでは一定の抑止効果がありますが、外部公開の主防御としては不十分です。

**評価**

補助防御としては可、主要防御としては不足です。

**推奨対策**

- 永続ストア型のレート制限へ移行する
- もしくは入口側で IP 制限 / WAF / fail2ban 相当を併用する

## 現在の設定実態

現在のローカル設定では、管理公開に必要な以下の項目が設定済みです。

- `INJECTION_ADMIN_USERNAME`
- `INJECTION_ADMIN_PASSWORD`
- `INJECTION_SESSION_SECRET`

また、compose の 4001 公開は localhost 束縛へ変更済みです。

## 総合評価

- 現在の公開可否: 条件付きで可
- 条件: 現在設定した管理 credentials / session secret を維持し、4001 の localhost 束縛を崩さないこと
- 残課題: ログイン試行制限の永続化、管理 UI の軽微な運用警告整理

## 公開前の必須チェックリスト

- `INJECTION_ADMIN_USERNAME` を十分長くランダムな値で設定
- `INJECTION_ADMIN_PASSWORD` を十分長くランダムな値で設定
- `INJECTION_SESSION_SECRET` を十分長いランダム値で設定
- token 検証側も unsafe 構成を拒否すること
- 4001 を 127.0.0.1 束縛または内部ネットワーク限定に変更すること
- tunnel 経由以外で 4001 に到達できないことを確認すること
- Secure cookie が有効で配布されることを実環境で確認すること

## 補足

今回の改修で、初回調査時にあった fail-open と 0.0.0.0 公開の主要問題は解消しました。現時点の残課題は主に防御強度の上積み領域であり、最低限の安全公開ラインには到達しています。