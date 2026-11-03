# aqua_wellplay / 星泉筆記本

AquariusLang notebooks in the spirit of JupyterLab. `aqua_wellplay` serves a folder over HTTP; the page it serves is an
AquariusLang app (SaturnUI, built for the web) that edits notebooks, and every cell runs on the computer running the
server, as Jupyter kernels do.

在瀏覽器中撰寫與執行星泉程式的筆記本，風格類似 JupyterLab。`aqua_wellplay` 在指定的資料夾上啟動網頁伺服器；網頁本身是以
星泉撰寫、編譯成網頁的 SaturnUI 應用程式，而儲存格在伺服器這台電腦上執行。

```powershell
aqua_wellplay                          # the current folder, http://127.0.0.1:8888/?token=..., opens a browser
aqua_wellplay D:\notes --port 9000     # another folder and port
aqua_wellplay --help
```

It ships beside `aqua` in the AquariusLang package, so the package folder on `PATH` gives both commands.

## What it does

- **Notebooks** are Jupyter's `.ipynb` (nbformat 4.5) with an AquariusLang kernelspec, so GitHub, JupyterLab and VS Code
  open them too. Code cells, Markdown cells, outputs and execution counts are saved; files are written as indented JSON
  with sources split into lines, as Jupyter writes them.
- **Cells** are [Aqua_Embedded_LSP_Editor](libraries/Aqua_Embedded_LSP_Editor) editors: highlighting, completion,
  hover, signature help and diagnostics from its built-in AquariusLang language server, native-feeling input (IME,
  selection, clipboard, context menu).
- **Running**: `Shift+Enter` (run and move on), `Ctrl+Enter` (run), `Alt+Enter` (run and insert), Run all, Stop
  (ends the process tree), Restart. Output streams while a cell runs; Run all stops at the first error, like Jupyter.
- **Rich output**: a cell's last expression shows as `Out[n]`; `Display` (also `顯示`) shows Markdown, tables, line /
  bar / area / scatter charts, images, JSON and progress, and an output given an id updates in place.
- **Interface**: a file browser (create, rename, delete notebooks and folders), tabs, a launcher, light and dark themes
  (the system's by default), Jupyter's command-mode keys (`A`, `B`, `D D`, `M`, `Y`, `↑`/`↓`, `I I`, `0 0`), autosave.

```aquarius
var data = [3, 1, 4, 1, 5, 9, 2, 6];
Display.Show(Display.Markdown("## Sales · 銷售"));
Display.Table(Array.Map(data, v => ({"value": v, "square": v * v})));
Display.Show(Display.LineChart(data, title: "Trend"), "chart");       # an output with an id
Display.Update("chart", Display.BarChart(data, title: "Trend"));      # replaced in place
Display.Image("plot.png", 320);                                       # a file next to the notebook, 320 wide
```

| `Display` / `顯示` | |
| --- | --- |
| `Show(value, id?)` / `顯示`, `Update(id, value)` / `更新`, `Clear(wait?)` / `清除` | send an output (an id makes it updatable), replace it, clear the cell's outputs (`wait`: when the next one arrives) |
| `Markdown(text)`, `Text(text)` / `文字`, `JSON(value)`, `Data(bundle, metadata?)` | rich values; the last expression of a cell or `Show` displays them |
| `Table(rows, columns?)` / `表格` | rows are arrays, or hashes whose keys make the columns |
| `LineChart` / `折線圖`, `BarChart` / `長條圖`, `AreaChart` / `區域圖`, `ScatterChart` / `散佈圖` `(series, title:, labels:, height:)`, `Chart(spec)` / `圖表` | series: numbers, `{"name": numbers}`, or `[{"name", "values" \| "points": [[x, y]]}]` |
| `Image(path \| image \| bytes, width?)` / `圖片` | PNG, JPEG or GIF files, Images module images, encoded bytes |
| `Progress(value, maximum?, label?)` / `進度` | a progress bar (with an id, update it as work advances) |

## How it works

```text
┌──────────── browser (web target) ────────────┐   JSON-RPC 2.0    ┌──────────── aqua_wellplay (desktop) ─────────────┐
│ frontend/: SaturnUI app on a Processing      │   over WebSocket  │ server/: Network library (Go-style HTTP server)  │
│ canvas, Interaction input                    │ ◀───────────────▶ │  GET /…       the frontend site                  │
│  cells: Aqua_Embedded_LSP_Editor (Immediate) │      /rpc         │  /rpc         files/*, notebook/*, kernel/*      │
│  outputs: MIME bundle → widgets              │ ◀── kernel/* ──── │  kernel.aqua: one program per execution:         │
│  app state, autosave, shortcuts              │   notifications   │   display module + history + cells → aqua run    │
└──────────────────────────────────────────────┘                   │   Terminal.Start: streamed output, Kill          │
                                                                    └──────────────────────────────────────────────────┘
```

- **The kernel** (`server/kernel.aqua`). The runtime cannot load new code into a running program, so every execution
  compiles one program: `kernel/display.aqua`, then the cells this notebook already ran successfully (their output
  hidden), then the cells to run, each after a marker line. The program is a hidden `.wellplay-*.aqua` file in the
  notebook's folder started with `aqua run`, so `目前工作目錄` / `currWorkingDir` is the notebook's folder, `.aqua` files
  there can be imported, and inside a Bottle project the project's libraries are available. Running a cell again
  replaces its earlier version in place, and a run replays the history only up to the first cell it runs. A cell that
  fails stays out of the history; Restart clears it. Earlier cells therefore run again each time (their side effects
  repeat), as in `aqua repl`.
- **The display protocol** (`kernel/display.aqua`). Rich outputs are lines on standard output: the record separator
  U+001E, the run's random token, then JSON (`display`, `update`, `result`, `clear`, `cell`). Everything else is the
  cell's text; `ERROR: …` is a runtime error; compile errors (`file:line:column: message` on standard error) map back
  to the cell, line and column. Outputs reach the frontend as nbformat output objects (`stream`, `display_data`,
  `execute_result`, `error`), so the same MIME bundles are what the `.ipynb` stores.
- **The frontend** renders each bundle in this order: progress, chart, table, image, Markdown, JSON, plain text
  (`frontend/src/outputs.aqua`; a new MIME type is one more entry in `renderers`).
- **Security**: the server listens on 127.0.0.1 by default; `/rpc` requires the token printed in the URL and a request
  from the server's own origin, so other pages cannot run code on the machine.

### Protocol

| Request | Result |
| --- | --- |
| `wellplay/info` | `{name, version, root, rootName, platform, aqua}` |
| `files/list {path}`, `files/read {path}`, `files/save {path, text}`, `files/create {path, kind}`, `files/rename {from, to}`, `files/delete {path}` | entries `{name, path, kind: directory \| notebook \| script \| file, size, modified}`; paths are relative to the served folder and cannot leave it |
| `notebook/open {path}`, `notebook/save {path, notebook}` | the normalized notebook and the kernel's state |
| `kernel/execute {path, cells: [{id, source}]}`, `kernel/interrupt {path}`, `kernel/restart {path}`, `kernel/sessions` | |

Notifications: `kernel/status`, `kernel/queued`, `kernel/started {cell, count}`, `kernel/output {cell, output}`,
`kernel/update {display, output}`, `kernel/clear {cell, wait}`, `kernel/finished {cell, status: ok | error | aborted,
milliseconds}`, `kernel/restarted`.

## Layout

```text
aqua.toml                   the server project (aqua_wellplay; desktop)
server/                     main.aqua (command line, HTTP, security), workspace.aqua (files), notebooks.aqua (.ipynb),
                            kernel.aqua (executions), protocol.aqua (JSON-RPC methods)
kernel/display.aqua         the display module compiled in front of every cell program
frontend/                   the web app: main.aqua (window, input, shortcuts), src/app.aqua (state, connection,
                            actions), src/views.aqua (screens), src/editors.aqua (cell editors), src/outputs.aqua
                            (renderers, Markdown, charts), src/theme.aqua (palettes, style sheet)
libraries/                  vendored copies of Aqua_Embedded_LSP_Editor and Aqua_JSON-RPC (see libraries/README.md)
examples/Welcome.ipynb      a tour of every output
tests/                      run.ps1 + client/: the end-to-end test against a running server
build.ps1, build.sh         build into a package folder (the AquariusLang release runs them)
```

## Building and testing

In the AquariusLangTW repository (`tools/aqua_wellplay` is a submodule: `git submodule update --init`), the release
builds it: `scripts/publish-cli.ps1` runs `build.ps1 -Aqua <published aqua> -Output dist/aqua`, which writes
`aqua_wellplay.exe`, `wellplay/site/` (the frontend) and `wellplay/kernel/`. By hand:

```powershell
./build.ps1 -Aqua path/to/aqua -Output path/to/folder      # Linux: ./build.sh path/to/aqua path/to/folder
aqua build frontend --target web -o frontend/dist          # development: the server finds frontend/dist and kernel/
aqua run . D:\notes --no-browser                           # the server from the sources
./tests/run.ps1 -Aqua path/to/aqua                         # end to end: prints WELLPLAY_OK
```

Development builds use the vendored libraries through Bottle; when you change one, raise its version (or remove its
cached copy with `aqua bottle cache remove <name> <version>`), because the cache keeps one immutable copy per version.
`build.ps1` and `tests/run.ps1` use a cache of their own.

Requirements: an AquariusLang with `Terminal.Start`, `Application.Arguments`, compile errors with positions and
SaturnUI (AquariusLangTW after 0.1.6). The frontend needs a browser with WebGPU (Chrome, Edge).

## License

MIT (see LICENSE). The vendored libraries keep their own licenses.
