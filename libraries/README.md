# Libraries

Two AquariusLang libraries aqua_wellplay builds with, each its own repository linked here as a git submodule (pinned to
one commit; `git submodule update --init --recursive` fetches them, and `build.ps1` / `build.sh` do it when they are
missing). They are path dependencies of `aqua.toml` and `frontend/aqua.toml`.

| Library | Repository |
| --- | --- |
| `Aqua_Embedded_LSP_Editor` | https://github.com/Aquarius-Language/Aqua_Embedded_LSP_Editor |
| `Aqua_JSON-RPC` | https://github.com/Aquarius-Language/Aqua_JSON-RPC |

To update one: change it in its own repository (raising its version), then `git submodule update --remote
libraries/<name>`, set the version in `frontend/aqua.toml` (and `aqua.toml`), and commit here.
