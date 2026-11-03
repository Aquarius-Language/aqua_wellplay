# Aqua_Embedded_LSP_Editor / 星泉內嵌編輯器

An embeddable code editor for AquariusLang applications: cross-platform, independent of any graphics library, with
Language Server Protocol support through [Aqua_JSON-RPC](../Aqua_JSON-RPC). Import `AquaEditor` / `星泉編輯器`.

可內嵌於星泉應用程式的程式碼編輯器：跨平台、與繪圖函式庫無關，透過 Aqua_JSON-RPC 支援語言伺服器協定（LSP）。

```aquarius
var ed = import("AquaEditor");
var editor = ed.CreateEditor({"text": "print(\"hello\");", "measure": function(t) { return p.textWidth(t); }});
ed.Place(editor, 0, 0, 800, 600);
ed.Attach(editor, import("Interaction").Attach(p.platformWindow));   # native-like input
await ed.UseBuiltInLanguageServer(editor);                             # or ConnectLanguageServer(editor, endpoint)
# every frame:
ed.Update(editor, seconds);
ed.Paint(ed.RenderModel(editor), painter);    # painter: {"rect", "text", "line", "clip"?, "unclip"?}
```

## How it fits together

| Part | What it does |
| --- | --- |
| Editor (`src/editor.aqua`, `src/buffer.aqua`) | Lines, UTF-16 positions as LSP, selections, undo/redo with typing grouped, auto-closed brackets and quotes, smart indent and outdent, word navigation, clipboard. Input is Interaction events: press places the caret, double/triple click select a word/line, drags select, Shift extends, the wheel and touch fling scroll (ScrollView), the context menu (ContextMenu) offers cut/copy/paste/select all/suggest, keyboard commands follow each platform (Ctrl or ⌘), typed text and IME composition come as `text` / `composition` events (the text being composed shows underlined at the caret until it is committed), the input-method window follows the caret (`TextRect`), and the pointer is the text cursor over the text and the arrow over line numbers, scrollbars and popups (`CursorArea`). |
| Render model | Everything to draw in window coordinates: visible lines with colored runs, the caret (blinking at the platform's rate), selections, diagnostic squiggles, the completion list, hover, signature help, the context menu, scrollbars, a light or dark theme (dark when the system is). `Paint(model, painter)` draws it with any library given three functions; or draw the model yourself. |
| Highlighting (`src/highlight.aqua`) | Bilingual AquariusLang tokens: keywords (async / 非同步 included), constants, types after `:`, strings and multi-line strings, numbers, `#` and block comments, functions, builtins, modules, members. |
| LSP client (`src/client.aqua`) | initialize, didOpen, incremental didChange, completion (triggered by typing and `.`, filtered and sorted, snippets with `${1:x}` / `$0` stops), hover after the pointer rests, signature help on `(` and `,`, publishDiagnostics. Works with any LSP server reachable through an Aqua_JSON-RPC endpoint (WebSocket, TCP, in-process). |
| Built-in server (`src/server.aqua`) | An AquariusLang language server written in AquariusLang: completion of keywords in both languages, builtins, modules and their members (also `x = import("Array")` aliases), declared names and snippets; hover; signature help; document symbols; diagnostics for unbalanced brackets, unterminated strings and comments and `await` / `等待` inside synchronous functions. Serve it to remote editors with `ServeLanguageServer(endpoint)` (AquaLab does), or in-process with `UseBuiltInLanguageServer`. |

## API

| English | 繁體中文 | |
| --- | --- | --- |
| `CreateEditor(options)` | `建立編輯器` | `text`, `lineHeight` (20), `charWidth` (8, monospace without `measure`), `measure(text) → width`, `tabSize` (4), `uri`, `languageId` (`aquarius`), `readOnly`, `theme`, `clipboard` (`{"get", "set"}`), `autoClose` |
| `Place(editor, x, y, w, h)`, `Attach(editor, session)`, `HandleEvent(editor, event)`, `Update(editor, seconds)` | `放置`, `附加`, `處理事件`, `更新` | Layout, input, per-frame work |
| `RenderModel(editor)`, `Paint(model, painter)` | `繪製模型`, `繪製` | Output |
| `Text`, `SetText`, `Insert`, `Type`, `Select`, `SelectAll`, `SelectedText`, `HasSelection`, `Cursor`, `SetCursor`, `Undo`, `Redo`, `RunCommand`, `OnChange`, `OnCommand`, `SetTheme`, `SetReadOnly`, `SetFocus`, `Diagnostics`, `SetDiagnostics`, `TextWidth`, `LightTheme()`, `DarkTheme()` | `文字`, `設定文字`, `插入`, `打字`, `選取`, `全選`, `選取文字`, `有選取`, `游標`, `設定游標`, `復原`, `重做`, `執行命令`, `當變更`, `當命令`, `設定主題`, `設定唯讀`, `設定焦點`, `診斷`, `設定診斷`, `文字寬度`, `淺色主題`, `深色主題` | |
| `ConnectLanguageServer(editor, endpoint)`, `UseBuiltInLanguageServer(editor)`, `DisconnectLanguageServer(editor)`, `ServeLanguageServer(endpoint)` | `連接語言伺服器`, `使用內建語言伺服器`, `中斷語言伺服器`, `提供語言伺服器` | async; resolve with the server's capabilities |
| `Tokenize(text)`, `Diagnose(text)`, `Complete(text, line, character)`, `Hover(text, line, character)` | `上色`, `分析診斷`, `建議`, `說明` | The analyses without LSP |

## Platforms and tests

Every target (Windows, Linux, Android, web): the editor only needs Interaction's events and something that draws. Keys act by
their `edit` action (Interaction's editing table), so word moves, line ends, word deletes and the keypad follow each
platform's rules.
`tests/editor.aqua` feeds events through an Interaction session and prints `EDITOR_OK`; `examples/processing` is a
Processing host (desktop, web, Android); [AquaLab](../AquariusLangTW_AquaLab) embeds it in a full-stack web app.
Needs an AquariusLang runtime with async functions and Interaction's `text` events and cursor areas (AquariusLang 0.1.7 or later).
