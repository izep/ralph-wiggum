# Ralph Loop for GitHub Copilot CLI
# PowerShell version

# Source common functions
$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

# Configuration
$MAX_ITERATIONS = 0
$MODE = "build"
$COPILOT_CMD = if ($env:COPILOT_CMD) { $env:COPILOT_CMD } else { "copilot" }
$RLM_CONTEXT_FILE = ""

# Helper
function Show-Help {
    Write-Host "Ralph Loop for GitHub Copilot CLI (PowerShell)"
    Write-Host "Usage: .\scripts\ralph-loop-copilot.ps1 [iterations] [plan]"
}

# Simple arg parsing
$args_array = $args
for ($i = 0; $i -lt $args_array.Length; $i++) {
    switch ($args_array[$i]) {
        "plan" { $MODE = "plan"; $MAX_ITERATIONS = 1 }
        { $_ -match '^\d+$' } { $MAX_ITERATIONS = [int]$_ }
        "--rlm" { $RLM_CONTEXT_FILE = "rlm\context.txt" }
    }
}

Set-Location $PROJECT_DIR

# Run common initialization
Initialize-Ralph -Mode $MODE -RlmContextFile $RLM_CONTEXT_FILE

# Get YOLO state
$YOLO_ENABLED = Get-YoloState

$timestamp_log = Get-Date -Format "yyyyMMdd_HHmmss"
$SESSION_LOG = Join-Path $LOG_DIR "ralph_copilot_${MODE}_session_${timestamp_log}.log"
Start-Transcript -Path $SESSION_LOG -Append

try {
    $ITERATION = 0
    while ($true) {
        if ($MAX_ITERATIONS -gt 0 -and $ITERATION -ge $MAX_ITERATIONS) { break }
        $ITERATION++

        $PROMPT_FILE = if ($MODE -eq "plan") { "PROMPT_plan.md" } else { "PROMPT_build.md" }
        $promptContent = Get-Content $PROMPT_FILE -Raw

        $ts_file = Get-Date -Format "yyyyMMdd_HHmmss"
        $LOG_FILE = Join-Path $LOG_DIR "ralph_copilot_${MODE}_iter_${ITERATION}_${ts_file}.log"

        $COPILOT_FLAGS = @("-p")
        if ($YOLO_ENABLED) { $COPILOT_FLAGS += "--yolo" }

        Write-Host "${PURPLE}LOOP $ITERATION${NC}"

        # FIX: Pipe input to Copilot instead of passing as argument
        $COPILOT_OUTPUT = $promptContent | & $COPILOT_CMD $COPILOT_FLAGS 2>&1 | Tee-Object -FilePath $LOG_FILE  

        if ($COPILOT_OUTPUT -match "<promise>(ALL_)?DONE</promise>") {
            Write-Host "${GREEN}? Task completed${NC}"
            if ($MODE -eq "plan") { break }
        } else {
            Write-Host "${YELLOW}? Incomplete${NC}"
        }

        git push origin (git branch --show-current) 2>$null
        Start-Sleep -Seconds 2
    }
} finally {
    Stop-Transcript
}
