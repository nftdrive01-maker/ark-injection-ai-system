# Open Source Notices

This file lists major third-party open source components used together with ark-injection-ai-system.

Important:

- This repository itself is distributed under the NFTDrive Source-Available License in [LICENSE.md](LICENSE.md).
- The file below is not a replacement for upstream licenses.
- Each third-party component remains subject to its own original license terms.
- Voice models, datasets, and externally downloaded assets may have separate terms in addition to software licenses.

## Major Open Source Components

### 1. amica-nftdrive

- Project: amica-nftdrive
- Repository: https://github.com/nftdrive01-maker/amica-nftdrive
- Upstream base: Amica (`semperai/amica`)
- Role: Frontend chat UI / avatar UI
- License: MIT
- Local reference: `../amica/LICENSE`

### 2. Google Workspace MCP

- Project: google-workspace-mcp
- Role: Google Workspace integration over MCP
- License: MIT
- Local reference: `../google-workspace-mcp/LICENSE`

### 3. e-Stat MCP

- Project: estat-mcp
- Role: e-Stat integration over MCP
- License: Apache License 2.0
- Local reference: `../estat-mcp/LICENSE`

### 4. Style-Bert-VITS2-nftdrive

- Project: Style-Bert-VITS2-nftdrive
- Repository: https://github.com/nftdrive01-maker/Style-Bert-VITS2-nftdrive
- Upstream base: Style-Bert-VITS2
- Role: Voice synthesis engine
- License: GNU Affero General Public License v3.0
- Local reference: `../sbv2/Style-Bert-VITS2/LICENSE`

### 5. Piper / Piper-based runtime

- Project: Piper-related runtime and voice serving components
- Role: Voice synthesis runtime
- License: Refer to the upstream Piper project and the specific runtime/image used in deployment
- Note: Voice models can have separate licenses and usage restrictions from the runtime itself
- Local reference: `../piper/README.md`

## Additional Notes

### Default Runtime Model Notes

The default Ark-i configuration currently points at the following runtime models:

- Text chat model: `qwen2.5:7b`
- Vision model: `llava`
- Piper voice model: `ayousanz/piper-plus-tsukuyomi-chan`

License notes for those defaults:

- `qwen2.5:7b`: the upstream Qwen2.5 7B Instruct model is published under Apache-2.0.
- `llava`: verify the exact pulled Ollama tag before redistribution or hosted commercial rollout. A representative upstream reference, `llava-hf/llava-1.5-7b-hf`, is published under the Llama 2 Community License.
- `ayousanz/piper-plus-tsukuyomi-chan`: the model card states that its license follows the つくよみちゃんコーパス terms, which are separate from the Piper runtime license.

### Voice Models and Assets

Voice models, avatar assets, learned weights, and downloadable artifacts may be licensed separately from the application code.

Before redistribution or commercial deployment, confirm the license of:

- downloaded voice models
- model weights
- avatar assets
- fonts
- images and media

For the default Piper voice model used by this repository, the practical requirement is not a blanket commercial prohibition but compliance with the つくよみちゃんコーパス conditions, including credit display and restrictions on some public use cases and redistribution patterns.

Recommended attribution text for public software using the default Piper voice model:

> 本ソフトウェアの音声合成には、フリー素材キャラクター「つくよみちゃん」（© Rei Yumesaki）が無料公開している音声データを使用しています。
>
> ■つくよみちゃんコーパス（CV.夢前黎） https://tyc.rei-yumesaki.net/material/corpus/

### Container Images and Service Dependencies

This system also relies on container images and external services such as PostgreSQL, DBHub, Node.js, and other runtime dependencies. Those components are governed by their own upstream licenses and distribution terms.

### No Automatic Exhaustive List

This notice is a curated, high-level summary for repository publication. It is not a complete software bill of materials and does not enumerate every transitive dependency.

If you need a full dependency-level attribution set for distribution, generate a dependency inventory and collect the corresponding upstream license texts separately.