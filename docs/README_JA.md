# ark-injection-ai-system ドキュメント索引

このディレクトリは、ark-injection-ai-system 全体を対象にした日本語ドキュメントセットです。

補足:
- 基本スタックは Amica / injection-tool / mcp-server / TTS / PostgreSQL / DBHub です
- `google-workspace-mcp` と `estat-mcp` は必要時のみ追加する optional サービスです

対象読者:
- 外部説明向け: システムの目的、全体像、主要機能を短時間で把握したい人
- 管理者向け: injection-tool 管理画面、公開設定、ドメイン管理、MCP 管理を担当する人
- 運用担当向け: Docker 起動停止、公開運用、障害切り分け、TTS 切替を担当する人
- 開発者向け: サービス境界、データフロー、設定値、拡張ポイントを把握したい人

読む順番の目安:
1. 外部説明や提案資料を作る場合
   - 01_SYSTEM_OVERVIEW_JA.md
   - 02_ARCHITECTURE_AND_DATAFLOW_JA.md
   - 06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md
2. 初回セットアップを行う場合
   - 15_INSTALLATION_MANUAL_JA.md
   - 05_SETUP_AND_DEPLOYMENT_JA.md
   - 10_CONFIGURATION_REFERENCE_JA.md
   - 09_TROUBLESHOOTING_JA.md
   - Google Workspace や e-Stat を使う場合は関連 MCP の説明もあわせて読む
3. 日常運用を行う場合
   - 07_ADMIN_AND_OPERATOR_MANUAL_JA.md
   - 08_RUNTIME_OPERATIONS_JA.md
   - 16_MODEL_SWITCH_MANUAL_JA.md
   - 17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md
   - 18_FULL_WSL2_INSTALLATION_MANUAL_JA.md
   - 09_TROUBLESHOOTING_JA.md
   - 12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md
   - Google Workspace や e-Stat を使う場合は 05_SETUP_AND_DEPLOYMENT_JA.md の optional MCP 手順も確認する
4. 技術仕様を把握したい場合
   - 02_ARCHITECTURE_AND_DATAFLOW_JA.md
   - 03_TECHNICAL_SPEC_JA.md
   - 04_TECH_STACK_JA.md
5. injection-tool 管理画面を安全に外部公開したい場合
   - 11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md
   - 12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md
   - 13_CLOUDFLARE_ACCESS_SETUP_JA.md
6. Piper TTS を導入・切替したい場合
   - 14_PIPER_TTS_SETUP_AND_SWITCH_JA.md

ドキュメント一覧:
- [01_SYSTEM_OVERVIEW_JA.md](./01_SYSTEM_OVERVIEW_JA.md)
- [02_ARCHITECTURE_AND_DATAFLOW_JA.md](./02_ARCHITECTURE_AND_DATAFLOW_JA.md)
- [03_TECHNICAL_SPEC_JA.md](./03_TECHNICAL_SPEC_JA.md)
- [04_TECH_STACK_JA.md](./04_TECH_STACK_JA.md)
- [05_SETUP_AND_DEPLOYMENT_JA.md](./05_SETUP_AND_DEPLOYMENT_JA.md)
- [06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md](./06_SECURITY_AND_PUBLIC_EXPOSURE_JA.md)
- [07_ADMIN_AND_OPERATOR_MANUAL_JA.md](./07_ADMIN_AND_OPERATOR_MANUAL_JA.md)
- [08_RUNTIME_OPERATIONS_JA.md](./08_RUNTIME_OPERATIONS_JA.md)
- [09_TROUBLESHOOTING_JA.md](./09_TROUBLESHOOTING_JA.md)
- [10_CONFIGURATION_REFERENCE_JA.md](./10_CONFIGURATION_REFERENCE_JA.md)
- [11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md](./11_INJECTION_TOOL_4001_TUNNEL_SECURITY_REVIEW_JA.md)
- [12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md](./12_CLOUDFLARE_ACCESS_CHECKLIST_JA.md)
- [13_CLOUDFLARE_ACCESS_SETUP_JA.md](./13_CLOUDFLARE_ACCESS_SETUP_JA.md)
- [14_PIPER_TTS_SETUP_AND_SWITCH_JA.md](./14_PIPER_TTS_SETUP_AND_SWITCH_JA.md)
- [15_INSTALLATION_MANUAL_JA.md](./15_INSTALLATION_MANUAL_JA.md)
- [16_MODEL_SWITCH_MANUAL_JA.md](./16_MODEL_SWITCH_MANUAL_JA.md)
- [17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md](./17_WSL2_WINDOWS_OLLAMA_MANUAL_JA.md)
- [18_FULL_WSL2_INSTALLATION_MANUAL_JA.md](./18_FULL_WSL2_INSTALLATION_MANUAL_JA.md)

既存の詳細資料:
- ark-injection-ai-system/EXTERNAL_PUBLISH_MANUAL_JA.md
- ark-injection-ai-system/SBV2_CPU_CUDA_SWITCH_MANUAL_JA.md
- injection-tool/README.md
- injection-tool/IMPLEMENTATION_GUIDE.md
- injection-tool/GOOGLE_WORKSPACE_MCP_MANUAL_JA.md
- amica/PUBLIC_DEPLOYMENT_MANUAL_JA.md  （amica-nftdrive のローカル配置先）
- amica/CONFIG_MANUAL_JA.md  （amica-nftdrive のローカル配置先）
- google-workspace-mcp/README.md
- estat-mcp/README.md
- mcp-server/README.md

この docs は上記の既存資料を置き換えるものではなく、ark-injection-ai-system 全体を運用・説明するために再構成した入口資料です。
