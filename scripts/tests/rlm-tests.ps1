$ErrorActionPreference = "Stop"

$ROOT_DIR = Resolve-Path "$PSScriptRoot\..\.."
$TMP_DIR = Join-Path ([IO.Path]::GetTempPath()) ("rlm_ps_{0}" -f (Get-Random))

function Cleanup {
    if (Test-Path $TMP_DIR) {
        Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Pass($msg) { Write-Host "✅ $msg" }
function Fail($msg) { Write-Host "❌ $msg"; Cleanup; exit 1 }

try {
    Cleanup
    New-Item -ItemType Directory -Path $TMP_DIR -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts\lib") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR ".specify\memory") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "specs") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "rlm\queries") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "rlm\answers") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "logs") -Force > $null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "bin") -Force > $null

    Copy-Item "$ROOT_DIR\scripts\ralph-loop.ps1" (Join-Path $TMP_DIR "scripts")
    Copy-Item "$ROOT_DIR\scripts\ralph-loop-codex.ps1" (Join-Path $TMP_DIR "scripts")
    Copy-Item "$ROOT_DIR\scripts\rlm-subcall.ps1" (Join-Path $TMP_DIR "scripts")
    Copy-Item "$ROOT_DIR\scripts\lib\common.ps1" (Join-Path $TMP_DIR "scripts\lib")

    "# Test Constitution`nYOLO Mode: ENABLED" | Set-Content (Join-Path $TMP_DIR ".specify\memory\constitution.md") -Encoding UTF8
    "# spec" | Set-Content (Join-Path $TMP_DIR "specs\001-test.md") -Encoding UTF8
    "dummy context" | Set-Content (Join-Path $TMP_DIR "rlm\context.txt") -Encoding UTF8
    "subcall query" | Set-Content (Join-Path $TMP_DIR "rlm\queries\q1.md") -Encoding UTF8

$claudeStub = Join-Path $TMP_DIR "bin\claude.ps1"
@'
param()
foreach ($chunk in $input) { }
Write-Output "stub claude output"
Write-Output "<promise>DONE</promise>"
$global:LASTEXITCODE = 0
'@ | Set-Content $claudeStub -Encoding UTF8

    $codexStub = Join-Path $TMP_DIR "bin\codex.ps1"
    @'
param()
$idx = [Array]::IndexOf($args, '--output-last-message')
if ($idx -ge 0 -and $idx + 1 -lt $args.Length) {
    $path = $args[$idx + 1]
    "<promise>DONE</promise>" | Set-Content $path -Encoding UTF8
}
foreach ($chunk in $input) { }
Write-Output "stub codex output"
$global:LASTEXITCODE = 0
'@ | Set-Content $codexStub -Encoding UTF8

    $env:CLAUDE_CMD = $claudeStub
    $env:CODEX_CMD = $codexStub
    $env:COPILOT_CMD = ""
    $env:GEMINI_CMD = ""

    Push-Location $TMP_DIR

    Write-Host "Running ralph-loop.ps1 (CLAUDE)..."
    pwsh -NoProfile -File ".\scripts\ralph-loop.ps1" 1 --rlm-context rlm\context.txt | Out-Null

    if (-not (Test-Path "rlm\index.tsv")) { Fail "rlm/index.tsv not created" }
    if (-not (Select-String -Path "rlm\index.tsv" -Pattern "done" -Quiet)) { Fail "rlm/index.tsv missing done status" }
    if (-not (Test-Path "rlm\trace\iter_1_prompt.md")) { Fail "prompt snapshot missing" }
    if (-not (Test-Path "rlm\trace\iter_1_output.log")) { Fail "output snapshot missing" }
    Pass "ralph-loop.ps1 creates logs and RLM workspace"

    Write-Host "Running ralph-loop-codex.ps1 (CODEX)..."
    pwsh -NoProfile -File ".\scripts\ralph-loop-codex.ps1" 1 --rlm-context rlm\context.txt | Out-Null
    if (-not (Select-String -Path "rlm\index.tsv" -Pattern "done" -Quiet)) { Fail "codex run did not update index" }
    Pass "ralph-loop-codex.ps1 completed"

    Write-Host "Running rlm-subcall.ps1..."
    pwsh -NoProfile -File ".\scripts\rlm-subcall.ps1" --agent claude --query rlm\queries\q1.md --context rlm\context.txt | Out-Null
    if (-not (Get-ChildItem -Path "rlm\answers" -Filter "subcall_*.md")) { Fail "rlm subcall output missing" }
    Pass "rlm-subcall.ps1 works"

    Pop-Location
} catch {
    Cleanup
    throw
}

Cleanup
Write-Host ""
Write-Host "All RLM PowerShell tests passed." -ForegroundColor Green
