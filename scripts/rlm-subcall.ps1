# RLM Subcall Helper (Experimental)
# PowerShell version

# Source common functions
$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

# Colors
$NC = "`[0m"

$AGENT = ""
$QUERY_FILE = ""
$OUTPUT_FILE = ""
$CONTEXT_FILE = ""

$CLAUDE_CMD = if ($env:CLAUDE_CMD) { $env:CLAUDE_CMD } else { "claude" }
$CODEX_CMD = if ($env:CODEX_CMD) { $env:CODEX_CMD } else { "codex" }
$COPILOT_CMD = if ($env:COPILOT_CMD) { $env:COPILOT_CMD } else { "copilot" }
$GEMINI_CMD = if ($env:GEMINI_CMD) { $env:GEMINI_CMD } else { "gemini" }

# Arg parsing
$args_array = $args
for ($i = 0; $i -lt $args_array.Length; $i++) {
    switch ($args_array[$i]) {
        "--agent" { $AGENT = $args_array[++$i] }
        "--query" { $QUERY_FILE = $args_array[++$i] }
        "--output" { $OUTPUT_FILE = $args_array[++$i] }
        "--context" { $CONTEXT_FILE = $args_array[++$i] }
    }
}

if ([string]::IsNullOrEmpty($QUERY_FILE)) { Write-Error "Query file required"; exit 1 }

# Auto-detect agent
if ([string]::IsNullOrEmpty($AGENT)) {
    if (Get-Command $CLAUDE_CMD -ErrorAction SilentlyContinue) { $AGENT = "claude" }
    elseif (Get-Command $CODEX_CMD -ErrorAction SilentlyContinue) { $AGENT = "codex" }
    elseif (Get-Command $COPILOT_CMD -ErrorAction SilentlyContinue) { $AGENT = "copilot" }
    elseif (Get-Command $GEMINI_CMD -ErrorAction SilentlyContinue) { $AGENT = "gemini" }
}

# Ensure RLM dirs exist
Initialize-Ralph -Mode "subcall"

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$LOG_FILE = Join-Path $LOG_DIR "rlm_subcall_$ts.log"
if ([string]::IsNullOrEmpty($OUTPUT_FILE)) { $OUTPUT_FILE = Join-Path $RLM_ANSWERS_DIR "subcall_$ts.md" }     

$promptContent = Get-Content $QUERY_FILE -Raw
if (-not [string]::IsNullOrEmpty($CONTEXT_FILE)) {
    $promptContent += "`n`n---`n## RLM Context`n$CONTEXT_FILE"
}

$STATUS = "unknown"
try {
    switch ($AGENT) {
        "claude" {
            $promptContent | & $CLAUDE_CMD -p --dangerously-skip-permissions 2>&1 | Tee-Object -FilePath $LOG_FILE | Set-Content $OUTPUT_FILE
            $STATUS = "ok"
        }
        "codex" {
            $promptContent | & $CODEX_CMD exec - --output-last-message $OUTPUT_FILE 2>&1 | Tee-Object -FilePath $LOG_FILE
            $STATUS = "ok"
        }
        "copilot" {
            $promptContent | & $COPILOT_CMD --yolo 2>&1 | Tee-Object -FilePath $LOG_FILE | Set-Content $OUTPUT_FILE
            $STATUS = "ok"
        }
        "gemini" {
            $promptContent | & $GEMINI_CMD 2>&1 | Tee-Object -FilePath $LOG_FILE | Set-Content $OUTPUT_FILE  
            $STATUS = "ok"
        }
    }
} catch {
    $STATUS = "error"
}

"$timestamp`trlm-subcall`t0`t$QUERY_FILE`t$LOG_FILE`t$OUTPUT_FILE`t$STATUS" | Add-Content $RLM_INDEX
Write-Host "RLM subcall complete."
