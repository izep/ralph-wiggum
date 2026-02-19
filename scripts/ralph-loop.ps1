# Ralph Loop for Claude Code
# PowerShell version

# Source common functions
$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

# Configuration
$MAX_ITERATIONS = 0 # 0 = unlimited
$MODE = "build"
$CLAUDE_CMD = if ($env:CLAUDE_CMD) { $env:CLAUDE_CMD } else { "claude" }
$YOLO_FLAG = "--dangerously-skip-permissions"
$RLM_CONTEXT_FILE = ""
$ROLLING_OUTPUT_LINES = 5
$ROLLING_OUTPUT_INTERVAL = 10

# Helper
function Show-Help {
    @"
Ralph Loop for Claude Code (PowerShell)

Based on Geoffrey Huntley's Ralph Wiggum methodology + SpecKit specs.
https://github.com/ghuntley/how-to-ralph-wiggum

Usage:
  .\scripts\ralph-loop.ps1              # Build mode, unlimited iterations
  .\scripts\ralph-loop.ps1 20           # Build mode, max 20 iterations
  .\scripts\ralph-loop.ps1 plan         # Planning mode (optional)
  .\scripts\ralph-loop.ps1 --rlm-context .\rlm\context.txt
  .\scripts\ralph-loop.ps1 --rlm .\rlm\context.txt
"@
}

# Parse arguments
$args_array = $args
for ($i = 0; $i -lt $args_array.Length; $i++) {
    switch ($args_array[$i]) {
        "plan" {
            $MODE = "plan"
            if ($i + 1 -lt $args_array.Length -and $args_array[$i+1] -match '^\d+$') {
                $MAX_ITERATIONS = [int]$args_array[$i+1]
                $i++
            } else {
                $MAX_ITERATIONS = 1
            }
        }
        "--rlm-context" {
            if ($i + 1 -lt $args_array.Length) {
                $RLM_CONTEXT_FILE = $args_array[$i+1]
                $i++
            }
        }
        "--rlm" {
            if ($i + 1 -lt $args_array.Length -and -not $args_array[$i+1].StartsWith("-")) {
                $RLM_CONTEXT_FILE = $args_array[$i+1]
                $i++
            } else {
                $RLM_CONTEXT_FILE = "rlm\context.txt"
            }
        }
        "-h" { Show-Help; exit }
        "--help" { Show-Help; exit }
        { $_ -match '^\d+$' } {
            $MODE = "build"
            $MAX_ITERATIONS = [int]$_
        }
        default {
            Write-Host "${RED}Unknown argument: $_${NC}"
            Show-Help
            exit 1
        }
    }
}

Set-Location $PROJECT_DIR

# Run common initialization
Initialize-Ralph -Mode $MODE -RlmContextFile $RLM_CONTEXT_FILE

# Get YOLO state
$YOLO_ENABLED = Get-YoloState

# Session log
$timestamp_log = Get-Date -Format "yyyyMMdd_HHmmss"
$SESSION_LOG = Join-Path $LOG_DIR "ralph_${MODE}_session_${timestamp_log}.log"
Start-Transcript -Path $SESSION_LOG -Append

# Check if Claude CLI is available
if (-not (Get-Command $CLAUDE_CMD -ErrorAction SilentlyContinue)) {
    Write-Host "${RED}Error: Claude CLI not found${NC}"
    exit 1
}

# Determine prompt file
$PROMPT_FILE = if ($MODE -eq "plan") { "PROMPT_plan.md" } else { "PROMPT_build.md" }

# Build Claude flags
$CLAUDE_FLAGS = @("-p")
if ($YOLO_ENABLED) { $CLAUDE_FLAGS += $YOLO_FLAG }

$CURRENT_BRANCH = git branch --show-current 2>$null
if (-not $CURRENT_BRANCH) { $CURRENT_BRANCH = "main" }

Write-Host ""
Write-Host "${GREEN}+-------------------------------------------------------------+${NC}"
Write-Host "${GREEN}¦              RALPH LOOP (Claude Code) STARTING              ¦${NC}"
Write-Host "${GREEN}+-------------------------------------------------------------+${NC}"
Write-Host ""
Write-Host "${BLUE}Mode:${NC}     $MODE"
Write-Host "${BLUE}Prompt:${NC}   $PROMPT_FILE"
Write-Host "${BLUE}Branch:${NC}   $CURRENT_BRANCH"
Write-Host "${YELLOW}YOLO:${NC}     $($YOLO_ENABLED ? "ENABLED" : "DISABLED")"
Write-Host ""

$ITERATION = 0
$CONSECUTIVE_FAILURES = 0
$MAX_CONSECUTIVE_FAILURES = 3

try {
    while ($true) {
        if ($MAX_ITERATIONS -gt 0 -and $ITERATION -ge $MAX_ITERATIONS) {
            Write-Host "${GREEN}Reached max iterations: $MAX_ITERATIONS${NC}"
            break
        }

        $ITERATION++
        $TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        Write-Host ""
        Write-Host "${PURPLE}?-------------------- LOOP $ITERATION --------------------?${NC}"
        Write-Host "${BLUE}[$TIMESTAMP]${NC} Starting iteration $ITERATION"
        Write-Host ""

        $ts_file = Get-Date -Format "yyyyMMdd_HHmmss"
        $LOG_FILE = Join-Path $LOG_DIR "ralph_${MODE}_iter_${ITERATION}_${ts_file}.log"

        # Snapshot prompt for RLM
        if (-not [string]::IsNullOrEmpty($RLM_CONTEXT_FILE)) {
            $RLM_PROMPT_SNAPSHOT = Join-Path $RLM_TRACE_DIR "iter_${ITERATION}_prompt.md"
            Copy-Item $PROMPT_FILE $RLM_PROMPT_SNAPSHOT
        }

        $RLM_STATUS = "unknown"

        # Run Claude
        $promptContent = Get-Content $PROMPT_FILE -Raw
        
        $CLAUDE_OUTPUT = ""
        try {
            $CLAUDE_OUTPUT = $promptContent | & $CLAUDE_CMD $CLAUDE_FLAGS 2>&1 | Tee-Object -FilePath $LOG_FILE
            Write-Host ""
            Write-Host "${GREEN}? Claude execution completed${NC}"

            if ($CLAUDE_OUTPUT -match "<promise>(ALL_)?DONE</promise>") {
                Write-Host "${GREEN}? Completion signal detected${NC}"
                $CONSECUTIVE_FAILURES = 0
                $RLM_STATUS = "done"

                if ($MODE -eq "plan") {
                    Write-Host "${GREEN}Planning complete!${NC}"
                    break
                }
            } else {
                Write-Host "${YELLOW}? No completion signal found${NC}"
                $CONSECUTIVE_FAILURES++
                $RLM_STATUS = "incomplete"

                if ($CONSECUTIVE_FAILURES -ge $MAX_CONSECUTIVE_FAILURES) {
                    Write-Host "${RED}? $MAX_CONSECUTIVE_FAILURES consecutive iterations without completion.${NC}"
                    $CONSECUTIVE_FAILURES = 0
                }
            }
        } catch {
            Write-Host "${RED}? Claude execution failed${NC}"
            $CONSECUTIVE_FAILURES++
            $RLM_STATUS = "error"
        }

        # Record RLM
        if (-not [string]::IsNullOrEmpty($RLM_CONTEXT_FILE)) {
            $RLM_OUTPUT_SNAPSHOT = Join-Path $RLM_TRACE_DIR "iter_${ITERATION}_output.log"
            Copy-Item $LOG_FILE $RLM_OUTPUT_SNAPSHOT
            "$TIMESTAMP`t$MODE`t$ITERATION`t$RLM_PROMPT_SNAPSHOT`t$LOG_FILE`t$RLM_OUTPUT_SNAPSHOT`t$RLM_STATUS" | Add-Content $RLM_INDEX
        }

        # Push changes
        git push origin "$CURRENT_BRANCH" 2>$null

        Write-Host ""
        Write-Host "${BLUE}Waiting 2s before next iteration...${NC}"
        Start-Sleep -Seconds 2
    }
} finally {
    Stop-Transcript
}

Write-Host ""
Write-Host "${GREEN}+-------------------------------------------------------------+${NC}"
Write-Host "${GREEN}         RALPH LOOP FINISHED ($ITERATION iterations)         ${NC}"
Write-Host "${GREEN}+-------------------------------------------------------------+${NC}"
