# Vendored libraries

Copies of two AquariusLang libraries that aqua_wellplay builds with, kept here so the tool builds from its own
repository alone. They are path dependencies of `aqua.toml` and `frontend/aqua.toml`.

| Library | Version | Source | Changes here |
| --- | --- | --- | --- |
| `Aqua_JSON-RPC` | 1.0.0 | Aqua_JSON-RPC (35db0ea) | none |
| `Aqua_Embedded_LSP_Editor` | 1.1.0 | Aqua_Embedded_LSP_Editor (c389402) | `PaintContent(model, painter)` and `PaintPopups(model, painter)` split `Paint`, so a host can draw popups (completion, hover, signature help, the context menu) above other content instead of inside the editor's clipped box; version raised from 1.0.0 |

To update one, copy the library's tracked files (without `examples/`) over its folder, reapply or upstream the changes
above, and raise its version when its sources differ from a version already released.
