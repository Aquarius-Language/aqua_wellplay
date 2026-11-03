# The end-to-end test: starts aqua_wellplay on a temporary folder, runs tests/client against it (JSON-RPC over
# WebSocket, cells compiled and run by the kernel), then tests/examples (every example notebook), and stops the
# server. Prints WELLPLAY_OK and EXAMPLES_OK and exits 0 on success.
#   tests/run.ps1 [-Aqua path/to/aqua] [-Port 8901]
param([string]$Aqua = 'aqua', [int]$Port = 8901)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$aquaPath = (Get-Command $Aqua -CommandType Application | Select-Object -First 1).Source
$work = Join-Path ([IO.Path]::GetTempPath()) "wellplay-test-$([Guid]::NewGuid().ToString('N'))"
$notebooks = Join-Path $work 'notebooks'
$site = Join-Path $work 'site'
New-Item -ItemType Directory -Path $notebooks, $site | Out-Null
Set-Content -LiteralPath (Join-Path $site 'index.html') -Value '<!doctype html><title>test</title>'
# A cache of its own: the libraries never meet other copies of the same versions.
$env:AQUA_BOTTLE_HOME = Join-Path $work 'bottles'
$token = 'test-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$log = Join-Path $work 'server.log'
$server = Start-Process -FilePath $aquaPath -PassThru -NoNewWindow -RedirectStandardOutput $log -RedirectStandardError "$log.err" `
    -ArgumentList @('run', "`"$root`"", "`"$notebooks`"", '--no-browser', '--port', $Port, '--token', $token, '--site', "`"$site`"", '--aqua', "`"$aquaPath`"")
try {
    $ready = $false
    for ($i = 0; $i -lt 240 -and -not $ready; $i++) {
        Start-Sleep -Milliseconds 500
        try { $ready = (Invoke-WebRequest -UseBasicParsing "http://127.0.0.1:$Port/health" -TimeoutSec 2).StatusCode -eq 200 } catch { }
        if ($server.HasExited) { break }
    }
    if (-not $ready) { Get-Content $log, "$log.err" -ErrorAction SilentlyContinue; throw 'The server did not start.' }
    $env:WELLPLAY_URL = "ws://127.0.0.1:$Port/rpc?token=$token"
    $output = & $aquaPath run (Join-Path $root 'tests/client') 2>&1 | Out-String
    Write-Host $output
    if (-not $output.Contains('WELLPLAY_OK')) { Get-Content $log -ErrorAction SilentlyContinue; throw 'The end-to-end test failed.' }
    # Every example notebook runs without an error (the window-opening ones are skipped).
    $examples = & $aquaPath run (Join-Path $root 'tests/examples') 2>&1 | Out-String
    Write-Host $examples
    if (-not $examples.Contains('EXAMPLES_OK')) { throw 'An example failed.' }
} finally {
    # The server and every cell program it started.
    & taskkill.exe /PID $server.Id /T /F | Out-Null
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
