$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

function Show-SubcallHelp {
    @"
RLM Subcall Helper (Experimental)

Usage:
  .\scripts\rlm-subcall.ps1 --query rlm\queries\q1.md
  .\scripts\rlm-subcall.ps1 --agent claude --query rlm\queries\q1.md --output rlm\answers\a1.md
  .\scripts\rlm-subcall.ps1 --agent codex --query rlm\queries\q1.md --context rlm\context.txt

Options:
  --agent <claude|codex|copilot|gemini>  Force specific agent (auto-detect if omitted)
  --query <file>                         Query prompt file (required)
  --output <file>                        Output file (default: rlm/answers/subcall_<ts>.md)
  --context <file>                       Large context file to treat as external environment
  -h, --help                             Show help
"@ | Write-Host
}

$argsArray = $args
$agent = ""
$queryFile = ""
$outputFile = ""
$contextFile = ""

for ($i = 0; $i -lt $argsArray.Length; $i++) {
    switch ($argsArray[$i]) {
        "--agent" {
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --agent requires a value" }
            $agent = $argsArray[$i + 1]
            $i++
        }
        "--query" { 
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --query requires a file" }
            $queryFile = $argsArray[$i + 1]
            $i++
        }
        "--query-file" {
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --query-file requires a file" }
            $queryFile = $argsArray[$i + 1]
            $i++
        }
        "--output" {
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --output requires a file" }
            $outputFile = $argsArray[$i + 1]
            $i++
        }
        "--context" {
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --context requires a file" }
            $contextFile = $argsArray[$i + 1]
            $i++
        }
        "--rlm-context" {
            if ($i + 1 -ge $argsArray.Length) { throw "Error: --rlm-context requires a file" }
            $contextFile = $argsArray[$i + 1]
            $i++
        }
        { $_ -in @("-h", "--help") } {
            Show-SubcallHelp
            exit 0
        }
        default {
            throw "Unknown argument: $($_)"
        }
    }
}

if (-not $queryFile) {
    throw "Error: --query <file> is required."
}

if (-not (Test-Path $queryFile)) {
    throw "Error: query file not found: $queryFile"
}

if ($contextFile -and -not (Test-Path $contextFile)) {
    throw "Error: context file not found: $contextFile"
}

$claudeCmd = if ($env:CLAUDE_CMD) { $env:CLAUDE_CMD } else { "claude" }
$codexCmd = if ($env:CODEX_CMD) { $env:CODEX_CMD } else { "codex" }
$copilotCmd = if ($env:COPILOT_CMD) { $env:COPILOT_CMD } else { "copilot" }
$geminiCmd = if ($env:GEMINI_CMD) { $env:GEMINI_CMD } else { "gemini" }

if (-not $agent) {
    if (Get-Command $claudeCmd -ErrorAction SilentlyContinue) {
        $agent = "claude"
    } elseif (Get-Command $codexCmd -ErrorAction SilentlyContinue) {
        $agent = "codex"
    } elseif (Get-Command $copilotCmd -ErrorAction SilentlyContinue) {
        $agent = "copilot"
    } elseif (Get-Command $geminiCmd -ErrorAction SilentlyContinue) {
        $agent = "gemini"
    } else {
        throw "Error: No supported CLI found (claude, codex, copilot, or gemini)."
    }
}

$agent = $agent.ToLower()
if ($agent -notin @("claude", "codex", "copilot", "gemini")) {
    throw "Error: unknown agent '$agent' (use 'claude', 'codex', 'copilot', or 'gemini')."
}

if (-not (Test-Path $LOG_DIR)) {
    New-Item -ItemType Directory -Path $LOG_DIR -Force > $null
}
New-Item -ItemType Directory -Path $RLM_TRACE_DIR, $RLM_QUERIES_DIR, $RLM_ANSWERS_DIR -Force > $null
if (-not (Test-Path $RLM_INDEX)) {
    "timestamp`tmode`titeration`tprompt`tlog`toutput`tstatus" | Set-Content -Path $RLM_INDEX -Encoding UTF8
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$tsFile = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LOG_DIR "rlm_subcall_${tsFile}.log"
$promptSnapshot = Join-Path $RLM_TRACE_DIR "subcall_${tsFile}_prompt.md"

Copy-Item -Path $queryFile -Destination $promptSnapshot -Force
if ($contextFile) {
    Add-Content -Path $promptSnapshot -Value (Get-RlmContextBlock -ContextPath (Resolve-Path $contextFile).Path)
}

if (-not $outputFile) {
    $outputFile = Join-Path $RLM_ANSWERS_DIR "subcall_${tsFile}.md"
}

$promptContent = Get-Content -Path $promptSnapshot -Raw
$status = "unknown"
$yoloEnabled = Get-YoloState

switch ($agent) {
"claude" {
        $flags = @("-p")
        if ($yoloEnabled) { $flags += "--dangerously-skip-permissions" }
        $argsList = @()
        $argsList += $flags
        $result = $promptContent | & $claudeCmd @argsList 2>&1 | Tee-Object -FilePath $logFile
        $success = ($LASTEXITCODE -eq 0)
        if ($success) {
            ($result | Out-String) | Set-Content -Path $outputFile -Encoding UTF8
            $status = "ok"
        } else {
            $status = "error"
        }
    }
    "codex" {
        $flags = @("exec")
        if ($yoloEnabled) { $flags += "--dangerously-bypass-approvals-and-sandbox" }
        $argsList = @()
        $argsList += $flags
        $argsList += "-"
        $argsList += @("--output-last-message", $outputFile)
        $result = $promptContent | & $codexCmd @argsList 2>&1 | Tee-Object -FilePath $logFile
        $status = if ($LASTEXITCODE -eq 0) { "ok" } else { "error" }
    }
    "copilot" {
        $flags = @("-p")
        if ($yoloEnabled) { $flags += "--yolo" }
        $argsList = @()
        $argsList += $flags
        $argsList += $promptContent
        $result = & $copilotCmd @argsList 2>&1 | Tee-Object -FilePath $logFile
        $success = ($LASTEXITCODE -eq 0)
        if ($success) {
            ($result | Out-String) | Set-Content -Path $outputFile -Encoding UTF8
            $status = "ok"
        } else {
            $status = "error"
        }
    }
    "gemini" {
        $flags = @("-p")
        if ($yoloEnabled) { $flags += "--yolo" }
        $argsList = @()
        $argsList += $flags
        $argsList += $promptContent
        $result = & $geminiCmd @argsList 2>&1 | Tee-Object -FilePath $logFile
        $success = ($LASTEXITCODE -eq 0)
        if ($success) {
            ($result | Out-String) | Set-Content -Path $outputFile -Encoding UTF8
            $status = "ok"
        } else {
            $status = "error"
        }
    }
}

$outputSnapshot = Join-Path $RLM_TRACE_DIR "subcall_${tsFile}_output.log"
Copy-Item -Path $logFile -Destination $outputSnapshot -Force

$indexEntry = "{0}`trlm-subcall`t0`t{1}`t{2}`t{3}`t{4}" -f $timestamp, $promptSnapshot, $logFile, $outputFile, $status
Add-Content -Path $RLM_INDEX -Value $indexEntry

Write-Host ""
Write-Host "RLM subcall complete."
Write-Host ("Agent:  {0}" -f $agent)
Write-Host ("Prompt: {0}" -f $promptSnapshot)
Write-Host ("Output: {0}" -f $outputFile)
Write-Host ("Log:    {0}" -f $logFile)
