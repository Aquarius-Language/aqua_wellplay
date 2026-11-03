# Builds aqua_wellplay into a distribution folder (the aqua package, or any folder):
#   <Output>/aqua_wellplay(.exe)        the server, a standalone executable of this machine's target
#   <Output>/wellplay/site/             the frontend, exported for the web
#   <Output>/wellplay/kernel/           the display module every cell program starts with
#   <Output>/wellplay/examples/         the example gallery (File › Examples)
#   ./build.ps1 -Aqua path/to/aqua -Output path/to/folder
# AquariusLangTW's scripts/publish-cli.ps1 runs it with the freshly published aqua. The vendored libraries build from a
# Bottle cache of their own (in the output's temporary folder), so they never meet other copies of the same versions.
param([string]$Aqua = 'aqua', [Parameter(Mandatory = $true)][string]$Output)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Desktop') { $IsWindows = $true }
$root = $PSScriptRoot
$aquaPath = (Get-Command $Aqua -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$Output = [IO.Path]::GetFullPath($Output)
$work = Join-Path ([IO.Path]::GetTempPath()) "aqua-wellplay-build-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $work | Out-Null
$savedBottles = $env:AQUA_BOTTLE_HOME
$env:AQUA_BOTTLE_HOME = Join-Path $work 'bottles'
function Invoke-Aqua([string[]]$Arguments) {
    & $aquaPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "aqua $($Arguments -join ' ') failed (exit $LASTEXITCODE)." }
}
try {
    # Locks are machine-specific (the Bottle cache holds the sources); build from the sources every time.
    Get-ChildItem -LiteralPath $root -Recurse -Filter aqua.lock.json -File | Remove-Item -Force
    $wellplay = Join-Path $Output 'wellplay'
    if (Test-Path -LiteralPath $wellplay) { Remove-Item -LiteralPath $wellplay -Recurse -Force }
    New-Item -ItemType Directory -Path $wellplay | Out-Null

    Write-Host 'aqua_wellplay: frontend (web)'
    Invoke-Aqua @('build', (Join-Path $root 'frontend'), '--target', 'web', '-o', (Join-Path $wellplay 'site'))
    Copy-Item -LiteralPath (Join-Path $root 'kernel') -Destination (Join-Path $wellplay 'kernel') -Recurse
    Copy-Item -LiteralPath (Join-Path $root 'examples') -Destination (Join-Path $wellplay 'examples') -Recurse

    Write-Host 'aqua_wellplay: server (standalone executable)'
    $target = if ($IsWindows) { 'windows' } elseif ($IsMacOS) { 'macos' } else { 'linux' }
    $name = if ($IsWindows) { 'aqua_wellplay.exe' } else { 'aqua_wellplay' }
    # The export puts the runtime's optional DLLs beside the executable; the server needs none of them, so only the
    # executable joins the package.
    $staging = Join-Path $work 'server'
    Invoke-Aqua @('build', $root, '--target', $target, '-o', (Join-Path $staging $name))
    Copy-Item -LiteralPath (Join-Path $staging $name) -Destination (Join-Path $Output $name) -Force
    Write-Host "aqua_wellplay: $(Join-Path $Output $name)"
} finally {
    $env:AQUA_BOTTLE_HOME = $savedBottles
    Get-ChildItem -LiteralPath $root -Recurse -Filter aqua.lock.json -File | Remove-Item -Force
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
