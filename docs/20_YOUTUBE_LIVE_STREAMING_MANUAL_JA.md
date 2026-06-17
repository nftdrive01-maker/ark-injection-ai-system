# YouTube ライブ配信連携 セットアップ・運用手順

## 目的

YouTube ライブ配信のチャットコメントを読み込み、AI（Amica のチャット）へ自動入力する配信連携機能のセットアップと運用手順をまとめます。
画面は OBS 等でキャプチャして配信する前提で、視聴者コメントに AI アバターが音声付きで応答する用途を想定します。

設定は injection-tool 管理画面の「配信設定」タブで、**ドメインごと**に行います。配信機能が OFF のドメインでは通常の会話動作に影響しません。

## 全体像

```
YouTube ライブチャット
   │  (YouTube Data API v3 / OAuth: youtube.readonly)
   ▼
injection-tool（サーバーサイドでポーリング・取り込みフィルタ適用。OAuthトークンは外部に出さない）
   │  GET /api/streaming/poll?domainId=...
   ▼  （Amica の BFF プロキシ /api/injection/streaming/poll 経由）
Amica（配速ポリシーに従い、AIアイドル時に1件ずつ受信）
   │  Chat.receiveMessageFromUser("○○さんからのコメント: …", false, domainId)
   ▼
LLM 応答生成 → 画面表示 + TTS（OBSがこの画面・音声をキャプチャ）
```

- コメント取得・OAuth トークン保持・取り込みフィルタは **injection-tool 側（サーバーサイド）** で完結します。
- Amica は BFF プロキシ経由でコメントを取得し、配速ポリシー（順次／最新／サンプリング）に従って AI へ流します。
- 配信機能が OFF のドメインでは Amica は一切コメントを投入しません。

## 関連ファイル

| ファイル | 役割 |
|---|---|
| `injection-tool/src/lib/streaming-settings.ts` | ドメインごとの配信設定ストア、OAuth トークン保管 |
| `injection-tool/src/lib/youtube-live.ts` | YouTube Data API クライアント、OAuth 交換/更新、ポーリング、取り込みフィルタ |
| `injection-tool/src/app/api/streaming/route.ts` | 設定の取得/保存（管理者認証） |
| `injection-tool/src/app/api/streaming/oauth/{start,callback,disconnect}/route.ts` | OAuth フロー |
| `injection-tool/src/app/api/streaming/poll/route.ts` | チャット取得（公開パス。OFF時は `enabled:false`） |
| `injection-tool/src/app/admin/page.tsx` | 管理画面「配信設定」タブ |
| `amica/src/features/streaming/useStreamingChat.ts` | コメント投入フック（OFF時無動作） |
| `amica/src/app/api/injection/[...path]/route.ts` | BFF 許可リスト（`streaming/poll`） |
| `injection-tool/data/streaming-settings.json` | 保存された設定（git管理外、初回保存時に生成） |
| `injection-tool/data/youtube-oauth.json` | OAuth トークン（git管理外、接続時に生成。**秘密情報**） |

## 前提条件

- 基本スタック（Amica / injection-tool）が起動済みであること
- 配信に使う YouTube チャンネルで、対象のライブ配信が**開始済み**かつ**チャットが有効**であること
- Google アカウント（対象チャンネルの所有者）でログインできること

## 1. Google Cloud 側の準備

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを用意（既存可）。
2. 「API とサービス」→「ライブラリ」で **YouTube Data API v3** を有効化する。
3. 「OAuth 同意画面」を構成し、スコープに `https://www.googleapis.com/auth/youtube.readonly` を追加する（外部公開アプリの場合はテストユーザーに自分のアカウントを追加）。
4. 「認証情報」→「認証情報を作成」→「OAuth クライアント ID」→ アプリの種類「**ウェブ アプリケーション**」を選ぶ。
5. **承認済みのリダイレクト URI** に次を登録する。

   ```
   http://localhost:4001/api/streaming/oauth/callback
   ```

   - 公開ホスト名や別ポートで管理画面を運用する場合は、その URL に合わせて登録し、後述の `STREAMING_OAUTH_REDIRECT_URI` も一致させる。
6. 発行された **クライアント ID** と **クライアントシークレット** を控える。

> n8n や Google Workspace MCP とは別の、配信専用 OAuth クライアントを新設する構成です。

## 2. `.env` の設定

`ark-injection-ai-system/.env` に専用 OAuth クライアントを設定します。

```dotenv
# YouTubeライブ配信連携(専用OAuthクライアント)
STREAMING_OAUTH_CLIENT_ID=<発行したクライアントID>
STREAMING_OAUTH_CLIENT_SECRET=<発行したクライアントシークレット>
STREAMING_OAUTH_REDIRECT_URI=http://localhost:4001/api/streaming/oauth/callback
```

設定後、injection-tool コンテナを再作成して環境変数を反映します。

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d --no-deps injection-tool
```

反映確認:

```bash
docker exec ark-injection-tool sh -c 'echo $STREAMING_OAUTH_CLIENT_ID'
```

## 3. 管理画面「配信設定」での操作

injection-tool 管理画面（`http://localhost:4001/admin`）→ タブ「**配信設定**」を開きます。

### 3.1 対象ドメインを選ぶ

- 「対象ドメイン」で配信連携を設定するドメインを選択します（設定はドメインごとに保存されます）。

### 3.2 Google アカウントを接続する

- 「YouTube接続」の「**Googleで接続**」を押すと Google 同意画面に遷移します。
- 許可すると `http://localhost:4001/admin?streaming=connected` に戻り、「接続済み（メールアドレス）」と表示されます。
- `STREAMING_OAUTH_*` が未設定の場合はボタンが無効化され、警告が表示されます。
- 接続解除は「接続解除」ボタン（`data/youtube-oauth.json` を削除）。

> 「refresh_token が取得できませんでした」と出る場合は、同意画面で「オフラインアクセス」を許可し、再度「Googleで接続」してください（本機能は `access_type=offline` + `prompt=consent` で要求します）。

### 3.3 チャット URL と有効化

- 「チャットURL」に配信の URL を貼り付けます。次のいずれも受け付けます。
  - `https://www.youtube.com/watch?v=XXXXXXXXXXX`
  - `https://youtu.be/XXXXXXXXXXX`
  - `https://www.youtube.com/live/XXXXXXXXXXX`
  - ライブチャットのポップアウト URL（`...live_chat?...&v=XXXXXXXXXXX`）
  - 11桁の動画 ID 直接入力
- 「このドメインで配信連携を有効にする」をチェックします。

### 3.4 取り込みポリシー（どのコメントを AI に渡すか）

| モード | 動作 |
|---|---|
| `auto` | 全コメントを順次取り込む |
| `keyword` | 指定キーワードのいずれかを含むコメントのみ（カンマ/改行区切りで複数指定） |
| `superchat` | スーパーチャット・メンバーシップ系のみ |
| `manual` | 自動送信せず取り込みのみ（AI へは流さない） |

- 「メンバーシップ系メッセージも取り込む」で、新規メンバー/メンバー限定系メッセージの取り込み有無を切り替えます。

### 3.5 配速ポリシー（コメント殺到時の捌き方）

| モード | 動作 |
|---|---|
| `sequential` | 届いた順に 1 件ずつ。AI が空いたら次を処理（積み残しも拾う） |
| `latest` | AI が空いた時点で常に最新コメントへジャンプし、積み残しは破棄 |
| `sampling` | 「サンプリング間隔（秒）」ごとに 1 件だけ拾う |

- 「キュー上限」は Amica 側に保持する待ち行列の最大数（0 で無制限）。

> 配速ポリシーは「取得済みコメントを AI にどう渡すか」の設定で、YouTube への問い合わせ回数（クォータ消費）は変えません。問い合わせ回数を抑えたい場合は次の「最小ポーリング間隔」を使います。

### 3.6 ポーリング（最小ポーリング間隔）

- 「最小ポーリング間隔（秒）」で、YouTube へ問い合わせる最短間隔を指定します（下限 2 秒）。
- 実際の間隔は **`max(この設定値, YouTube が返す推奨値 pollingIntervalMillis)`** になります。設定値より小さくはならず、賑わっている時の下限として機能します。
- 値を大きくするほど `liveChatMessages.list` の呼び出し回数が減り、**API クォータ消費を抑えられます**（例: 2 秒 → 10 秒で呼び出し回数は約 1/5）。
- 保存後、**次のポーリング周期から自動適用**されます（Amica の再起動・リロードは不要）。

### 3.7 投稿者名の扱い

- 「投稿者名を文脈として AI に渡す」を ON にすると、`○○さんからのコメント: 本文` の形で AI に渡り、名前を呼んで返答できます。OFF なら本文のみ。

### 3.8 保存

- 「配信設定を保存」を押すと `data/streaming-settings.json` に保存され、次回ポーリングから反映されます（再起動不要）。

## 4. 配信を流す

- OBS でキャプチャする画面（Amica）で、設定したドメインを開きます。
- 配信連携が有効なら、Amica が自動でコメントを取得し、配速ポリシーに従って AI へ投入します。
- AI の応答（画面・音声）が出るので、OBS でその画面と音声をキャプチャして配信します。

## 動作確認

### 1. poll API（サーバーサイド取得）

ドメインの取得状況を直接確認できます（`enabled` / `connected` / `messages` を返します）。

```bash
curl "http://127.0.0.1:4001/api/streaming/poll?domainId=<domainId>"
```

- `enabled:false` … そのドメインで配信連携が無効。
- `connected:false` … YouTube 未接続（OAuth 未完了）。
- `error` … 後述のトラブル確認へ。

### 2. Amica 側の投入確認

- 配信連携が有効なドメインを Amica で開き、ライブチャットに発言すると、AI がコメントに応答します。
- 投稿者名 ON の場合、`○○さんからのコメント: …` の形で会話に現れます。

## 公開時の注意

- Amica（3000）をトンネル公開する場合、コメント取得は Amica サーバー → injection-tool（内部）→ YouTube のサーバーサイド経路で完結します。**injection-tool（4001）や OAuth 情報を公開する必要はありません**。
- BFF 許可リストには読み取り専用の `streaming/poll` のみを追加しています。設定変更・OAuth 操作（4001 直）はトンネル越しには到達しません。
- 公開構成の考え方は [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md) / [11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md](./11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md) を参照。

## トラブル時の確認ポイント

### コメントが流れない

1. 「配信設定」で対象ドメインが**有効**か、チャット URL が正しいか。
2. 「YouTube接続」が**接続済み**か。
3. 対象ライブが**開始済み**でチャットが有効か（開始前・終了後は `activeLiveChatId` が取れません）。
4. poll API を直接叩いてエラー内容を確認:
   ```bash
   curl "http://127.0.0.1:4001/api/streaming/poll?domainId=<domainId>"
   ```
   - `アクティブなライブチャットが見つかりません` … 配信開始/チャット有効化を確認。
   - `HTTP 403` … YouTube Data API のクォータ超過、またはスコープ/権限不足。
   - `YouTube未接続です` … OAuth を再接続。

### 取り込みポリシーで絞りすぎていないか

- `keyword` モードでキーワード未設定だと、何も流れません（仕様）。
- `superchat` モードでは通常コメントは流れません。

### injection-tool ログ

```bash
docker logs --tail 100 ark-injection-tool
```

## 既知の注意

- **API クォータ**: YouTube Data API v3 は 1 日あたりのクォータ（既定 10,000 ユニット）があります。`liveChatMessages.list` はポーリングのたびに消費するため、長時間配信ではクォータに注意してください（取得間隔は `max(配信設定の「最小ポーリング間隔」, API が返す pollingIntervalMillis)`）。賑わっているチャットでは約 2 秒間隔（1 時間あたり〜1,800 回程度）になり得るため、長時間運用では「最小ポーリング間隔」を大きめ（例 10 秒）に設定するか、クォータ増加申請を検討してください。
- **ポーリングが走る条件**: 実際に YouTube を呼ぶのは「対象ドメインが有効（enabled）」かつ「Amica のタブが開いている」間だけです。配信設定でドメインを **OFF にして保存**すると injection-tool は YouTube API を一切呼ばなくなり（クォータ消費ゼロ）、Amica のタブを閉じてもポーリングは止まります。使わない時は OFF にしておくのが安全です。
- **OAuth トークンは秘密情報**: `data/youtube-oauth.json` には refresh token が含まれます。`.gitignore` 済みですが、バックアップ・共有時は取り扱いに注意してください。
- **配信終了・切替**: 配信が終了すると `liveChatId` が無効化されます。次回ポーリングで自動的に再解決を試みます。別の配信に切り替えたらチャット URL を更新してください。
- **AI ルーターと同様の到達性**: コメント取得は injection-tool（サーバーサイド）から外部 YouTube へ HTTPS で行います。社内プロキシ等がある環境では到達性を確認してください。

## 関連資料

- [07_ADMIN_AND_OPERATOR_MANUAL_JA.md](./07_ADMIN_AND_OPERATOR_MANUAL_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- [02_ARCHITECTURE_AND_DATAFLOW_JA.md](./02_ARCHITECTURE_AND_DATAFLOW_JA.md)
