# Aqua_JSON-RPC / 星泉遠端呼叫

[JSON-RPC 2.0](https://www.jsonrpc.org/specification) for AquariusLang, written in AquariusLang only. Import
`AquaJSONRPC` / `星泉遠端呼叫` through a Bottle dependency.

星泉的 JSON-RPC 2.0 函式庫，完全以星泉撰寫：請求、通知、回應、批次與標準錯誤碼都依規格實作；端點是雙向的，
呼叫回傳承諾，處理函式可以是非同步函式。

```aquarius
var rpc = import("AquaJSONRPC");
var net = import("Network");
var server = net.Listen(":8080");
var api = rpc.CreateEndpoint(null);
api.Handle("add", function(params) { return params["a"] + params["b"]; });
api.Handle("greet", async function(params, context) { await Promise.Delay(10); return "hello " + params[0]; });
rpc.ServeHttp(server, "/rpc", api);
server.Serve();
```

```aquarius
變數 遠端 = 匯入("AquaJSONRPC");
變數 用戶端 = 遠端.HTTP用戶端("http://127.0.0.1:8080/rpc", 空值);
印出(等待 用戶端.呼叫("add", {"a": 1, "b": 2}));                      # 3
變數 錯誤 = 等待 用戶端.呼叫("missing", []).捕捉(函式(e) { 回傳 e; });   # {"code": -32601, ...}
```

## Platforms / 平台

| Transport / 傳輸 | Windows, Linux, Android | Web |
| --- | --- | --- |
| `HttpClient(url, options)` / `HTTP用戶端` | ✅ | ✅ (fetch; the server must allow the page's origin) |
| `ConnectWebSocketAsync(url, options)` / `WebSocket連線` | ✅ (`ws`, `wss`) | ✅ |
| `CreatePair()` / `建立配對` (in-process) | ✅ | ✅ |
| `ServeHttp(server, path, endpoint)` / `HTTP服務` | ✅ | — (browsers cannot listen) |
| `ServeWebSocket(server, path, onConnect)` / `WebSocket服務` | ✅ | — |
| `ConnectTCPAsync(host, port)`, `ServeTCP(address, port, onConnect)`, `StreamEndpoint(stream)` | ✅ (Content-Length framing, as LSP) | — (no raw sockets in browsers) |
| `CreateEndpoint(send)` + `Receive(text)` / `建立端點` + `接收` | any transport you bring / 任何傳輸 | ✅ |

The servers run on the default `Network` library, so `https` / `wss` work with its certificate options, and HTTP
and WebSocket endpoints share one port with your other routes.

## Endpoints / 端點

| English | 繁體中文 | |
| --- | --- | --- |
| `Handle(method, handler)` | `處理(方法, 函式)` | `handler(params, context)` returns a value, an `Error(...)` or a promise; it may take fewer parameters. `context` has `method`, `id` and `endpoint` (to call or notify back). |
| `OnNotification(method, handler)` | `當通知` | Notifications get no response. |
| `HandleOther(handler)` | `處理其他` | `handler(method, params, context)` for anything unregistered (proxies). |
| `Call(method, params)` | `呼叫` | A promise of the result; rejects with `{"code", "message", "data"}`. |
| `Notify(method, params)` | `通知` | |
| `Batch([[method, params], [method, params, true], ...])` | `批次` | One batch message; a promise of `{"result"}` / `{"error"}` per call (null for notifications). |
| `Receive(text)` | `接收` | Hand incoming text to the endpoint; responses go to `send`. |
| `Process(text)` | `處理文字` | A promise of the response text (`""` for none): request/response transports. |
| `SetTimeout(ms)` | `設定逾時` | Per call (0, the default, waits forever); expired calls reject with -32000. |
| `Close()`, `Ended()`, `OnClose(fn)`, `OnError(fn)`, `PendingCount()`, `Methods()`, `IsClosed()` | `關閉`, `已結束`, `當關閉`, `當錯誤`, `待回應數`, `方法列表`, `已關閉` | Closing rejects pending calls with -32001. |

Errors: `ParseError` -32700, `InvalidRequest` -32600, `MethodNotFound` -32601, `InvalidParams` -32602,
`InternalError` -32603 (a runtime error in a handler, with its message), and in the server range `TimeoutError`
-32000, `ClosedError` -32001, `TransportError` -32002. `Error(code, message, data)` / `錯誤` makes one (a null message
takes the standard text), `InvalidParamsError(message)` / `參數錯誤` the -32602 one, `IsError(value)` / `是錯誤`
recognizes them. Message helpers: `Request`, `Notification`, `ResultResponse`, `ErrorResponse`, `Kind(message)`
(`"request"`, `"notification"`, `"response"`, `"batch"`, `"invalid"`), `ToJSON`, `Parse`, and the LSP base protocol's
`Frame(text)` / `分框` (bytes with a `Content-Length` header) and `CreateFrameReader()` / `建立分框讀取器` (`Feed(bytes)`,
`Take()`).

## Spec conformance / 規格

Requests and notifications with positional (array) or named (object) parameters; ids that are strings, numbers or
null; batches answered with one array in which notifications have no entry (nothing at all when every member was a
notification, an `Invalid Request` for an empty batch, one error per invalid member); `Parse error` with a null id;
`Method not found` with the method in `data`. Responses for unknown ids go to `OnError`.

## Tests / 測試

```powershell
aqua run tests/protocol.aqua     # the specification's examples, pairs, batches, timeouts, framing: JSONRPC_PROTOCOL_OK
aqua run tests/transports.aqua   # HTTP, WebSocket and TCP (desktop, Android): JSONRPC_TRANSPORTS_OK
```

`tests/protocol.aqua` also runs on the web (`aqua build tests/protocol.aqua -o p.wasm`, then the repository's
`scripts/web-run.mjs`). Needs an AquariusLang runtime with async functions, the Network library's promise variants and
`arityOf` (the release after 0.1.6).
