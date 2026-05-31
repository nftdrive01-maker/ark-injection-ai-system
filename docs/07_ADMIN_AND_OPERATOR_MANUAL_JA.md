# 管理画面と運用者向け操作マニュアル

## 対象

この資料は主に injection-tool 管理画面を操作する管理者向けです。

管理画面の入口:
- `http://localhost:4001/login`
- ログイン後: `http://localhost:4001/admin`

## 管理画面でできること

管理画面には複数のタブがあり、主に以下の機能を持ちます。

| タブ | 主な目的 |
|---|---|
| Domain | ドメイン設定、プロンプト、UI・音声・連携先の紐付け |
| Shared Log | 共有ログの確認 |
| Knowledge | ナレッジ作成、編集、クロール |
| Chronicle | Chronicle 管理 |
| Asset | アセット管理 |
| Pronunciation | 読み替えルール管理 |
| Public | 公開設定、同時接続数、レート制限、Cloudflare Tunnel |
| MCP | MCP サーバーの登録、テスト、ルーティング設定 |

## 基本操作

### 1. ログイン
1. `INJECTION_ADMIN_USERNAME` と `INJECTION_ADMIN_PASSWORD` を用意する
2. `/login` にアクセスする
3. 認証に成功すると `/admin` に入る

### 2. ドメインを作成または編集する
Domain タブで以下を管理できます。
- ドメイン ID
- 名前と説明
- base system prompt
- base context
- テーマカラー、背景、キャラクター名
- VRM / 画像アバター設定
- TTS ミュート
- TTS モデルやスタイル
- knowledgeIds
- mcpServerIds
- chronicleIds
- 共有ログやアクセス制御関連の設定

運用の考え方:
- ドメイン ID は会話ルーティングの基準になるため、途中変更は慎重に行う
- 画面見た目と知識セットをドメイン単位で分けると説明しやすい
- 実運用では用途ごとにドメインを切る

### 3. ナレッジを登録する
Knowledge タブでは、静的知識やクロール取得知識を管理できます。

代表操作:
- 新規 Knowledge 作成
- 既存 Knowledge 編集
- URL を指定したクロール
- 取得済み Knowledge の再取得して更新
- ドメインへの紐付け

### 4. MCP サーバーを登録する
MCP タブでは以下を扱えます。
- MCP サーバーの登録
- transport の選択
- URL / command / args 設定
- timeout 設定
- rule routing / ai routing 設定
- 接続テスト
- import URL からの取り込み

運用時のポイント:
- まず接続テストを通す
- Docker 内とホスト上では URL 解決先が異なるので注意する
- ルールベースで使う場合は tool 名と引数テンプレートを明示する

### 5. Public タブで公開設定を行う
Public タブでは以下を管理します。
- 最大同時接続数
- chat のユーザー当たり毎分リクエスト数
- tts のユーザー当たり毎分リクエスト数
- 派生する全体レートの確認
- Cloudflare Tunnel の起動・停止
- 公開対象 URL の選択

運用時の推奨:
- chat と tts は別設定で考える
- 公開前に同時接続数とレートの積を確認する
- トンネルは必要時のみ起動する

## Cloudflare Tunnel 操作

管理画面から quick tunnel の状態確認、起動、停止ができます。対象として以下を選べます。
- フロントアプリ
- injection-tool 管理面

原則推奨はフロントアプリのみの公開です。

## 共有ログと履歴の扱い

- 共有ログはドメイン単位で有効化・無効化できる
- チャット履歴やログは、利用形態によっては個人情報や業務情報を含むため、保存方針を事前に決める

## フロントアプリ側の基本操作

利用者向けの最低限の操作:
- ドメイン選択
- チャット入力
- マイク入力
- チャットモード切替
- 履歴検索表示
- Ark-i Core 表示と通常会話表示の切替

## 運用前チェック

- 管理者ログインできる
- ドメイン一覧が読み込める
- MCP サーバーが期待どおり登録されている
- Public 設定が保存できる
- Cloudflare Tunnel 状態を確認できる
- フロントアプリから対象ドメインで会話できる

## 関連資料

- 日常運用: [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- 障害対応: [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- セキュリティ: [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
