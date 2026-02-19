# RLM Integration Tests (PowerShell version)

$ROOT_DIR = Resolve-Path "$PSScriptRoot\..\.."
$TMP_DIR = [IO.Path]::Combine([IO.Path]::GetTempPath(), "rlm_test_$(Get-Random)")
New-Item -ItemType Directory -Path $TMP_DIR -Force >$null

function cleanup {
    Remove-Item -Path $TMP_DIR -Recurse -Force -ErrorAction SilentlyContinue
}

function pass($msg) { Write-Host "? $msg" -ForegroundColor Green }
function fail($msg) { Write-Host "? $msg" -ForegroundColor Red; exit 1 }

try {
    # Setup test environment
    $scriptsDir = New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts") -Force
    $libDir = New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "scripts\lib") -Force
    $binDir = New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "bin") -Force
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR ".specify\memory") -Force >$null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "specs") -Force >$null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "rlm\queries") -Force >$null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "rlm\answers") -Force >$null
    New-Item -ItemType Directory -Path (Join-Path $TMP_DIR "logs") -Force >$null

    Copy-Item "$ROOT_DIR\scripts\*.ps1" $scriptsDir
    Copy-Item "$ROOT_DIR\scripts\lib\*.ps1" $libDir
    
    "# Test Constitution`nYOLO Mode: ENABLED" | Set-Content (Join-Path $TMP_DIR ".specify\memory\constitution.md")
    "# spec" | Set-Content (Join-Path $TMP_DIR "specs\001-test.md")
    "dummy context" | Set-Content (Join-Path $TMP_DIR "rlm\context.txt")
    "subcall query" | Set-Content (Join-Path $TMP_DIR "rlm\queries\q1.md")

    # Stub Claude CLI
    "param(`$p)`nWrite-Host 'stub claude output'`nWrite-Host '<promise>DONE</promise>'" | Set-Content (Join-Path $binDir "claude.ps1")

    # Stub Codex CLI
    "param(`$f, `$u, `$m, `$o)`nWrite-Host 'stub codex output'`n'<promise>DONE</promise>' | Set-Content `$o" | Set-Content (Join-Path $binDir "codex.ps1")

    # Set up environment for scripts
    $env:PATH = "$binDir;" + $env:PATH
    $CLAUDE_STUB = "powershell -NoProfile -File $binDir\claude.ps1"
    $CODEX_STUB = "powershell -NoProfile -File $binDir\codex.ps1"

    Push-Location $TMP_DIR
    
    Write-Host "Running ralph-loop.ps1 (CLAUDE)..."
    $env:CLAUDE_CMD = $CLAUDE_STUB
    & "$scriptsDir\ralph-loop.ps1" 1 --rlm-context rlm\context.txt | Out-Null
    
    if (-not (Test-Path "rlm\index.tsv")) { fail "rlm/index.tsv not created" }
    if (-not (Select-String -Path "rlm\index.tsv" -Pattern "done" -Quiet)) { fail "rlm/index.tsv missing done status" }
    pass "ralph-loop.ps1 creates logs and RLM workspace"

    Write-Host "Running ralph-loop-codex.ps1 (CODEX)..."
    $env:CODEX_CMD = $CODEX_STUB
    & "$scriptsDir\ralph-loop-codex.ps1" 1 --rlm-context rlm\context.txt | Out-Null
    pass "ralph-loop-codex.ps1 completed"

    Pop-Location
} finally {
    cleanup
}

Write-Host "`nAll RLM tests passed." -ForegroundColor Green
