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

### Runtime Model Configuration Notes

This repository distributes application code, container configuration, and integration settings, but does not distribute model weights, voice models, or other learned artifacts.

Operators are responsible for selecting, obtaining, and configuring the models used for:

- text chat
- vision
- speech synthesis
- avatar presentation

Those models may be subject to separate licenses, terms of use, attribution requirements, export restrictions, or redistribution limits set by their respective providers.

### Voice Models and Assets

Voice models, avatar assets, learned weights, and downloadable artifacts may be licensed separately from the application code.

Before redistribution or commercial deployment, confirm the license of:

- downloaded voice models
- model weights
- avatar assets
- character models
- fonts
- images and media

This repository does not treat any particular third-party voice model, avatar asset, or character model as a bundled default distribution artifact. If an operator configures a specific Piper or Style-Bert-VITS2 voice model, avatar asset, or character model, that operator must comply with the terms of the corresponding provider.

When a chosen voice model or character asset requires attribution, redistribution limits, or commercial-use conditions, the operator must publish the required notices according to that provider's rules.

### Container Images and Service Dependencies

This system also relies on container images and external services such as PostgreSQL, DBHub, Node.js, and other runtime dependencies. Those components are governed by their own upstream licenses and distribution terms.

### No Automatic Exhaustive List

This notice is a curated, high-level summary for repository publication. It is not a complete software bill of materials and does not enumerate every transitive dependency.

If you need a full dependency-level attribution set for distribution, generate a dependency inventory and collect the corresponding upstream license texts separately.