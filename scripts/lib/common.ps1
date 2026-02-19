# Common functions and setup for Ralph Loop scripts

$PROJECT_DIR = Resolve-Path "$PSScriptRoot\.."
$LOG_DIR = Join-Path $PROJECT_DIR "logs"
$CONSTITUTION = Join-Path $PROJECT_DIR ".specify\memory\constitution.md"
$RLM_DIR = Join-Path $PROJECT_DIR "rlm"
$RLM_TRACE_DIR = Join-Path $RLM_DIR "trace"
$RLM_QUERIES_DIR = Join-Path $RLM_DIR "queries"
$RLM_ANSWERS_DIR = Join-Path $RLM_DIR "answers"
$RLM_INDEX = Join-Path $RLM_DIR "index.tsv"

# Colors (ANSI)
$RED = "`[0;31m"
$GREEN = "`[0;32m"
$YELLOW = "`[1;33m"
$BLUE = "`[0;34m"
$PURPLE = "`[0;35m"
$CYAN = "`[0;36m"
$NC = "`[0m"

function Initialize-Ralph {
    param (
        [string]$Mode,
        [string]$RlmContextFile
    )

    if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Path $LOG_DIR -Force >$null }

    # Validate RLM context file
    if (-not [string]::IsNullOrEmpty($RlmContextFile) -and -not (Test-Path $RlmContextFile)) {
        Write-Host "${RED}Error: RLM context file not found: $RlmContextFile${NC}"
        exit 1
    }

    # Initialize RLM workspace
    if (-not [string]::IsNullOrEmpty($RlmContextFile)) {
        New-Item -ItemType Directory -Path $RLM_TRACE_DIR, $RLM_QUERIES_DIR, $RLM_ANSWERS_DIR -Force >$null
        if (-not (Test-Path $RLM_INDEX)) {
            "timestamp`tmode`titeration`tprompt`tlog`toutput`tstatus" | Set-Content $RLM_INDEX
        }
    }

    # Create/update PROMPT_build.md
    $buildPrompt = @"
# Ralph Build Mode

Based on Geoffrey Huntley's Ralph Wiggum methodology.

---

## Phase 0: Orient

Read `.specify/memory/constitution.md` to understand project principles and constraints.

---
"@

    if (-not [string]::IsNullOrEmpty($RlmContextFile)) {
        $buildPrompt += @"

## Phase 0d: RLM Context (Optional)

You have access to a large context file at:
**$RlmContextFile**

Treat this file as an external environment. Do NOT paste the whole file into the prompt.
Instead, inspect it programmatically and recursively.
"@
    }

    $buildPrompt += @"

## Phase 1: Discover Work Items

Search for incomplete work from these sources (in order):

1. **specs/ folder** — Look for `.md` files NOT marked `## Status: COMPLETE`
2. **IMPLEMENTATION_PLAN.md** — If exists, find unchecked `- [ ]` tasks
3. **GitHub Issues** — Check for open issues (if this is a GitHub repo)
4. **Any task tracker** — Jira, Linear, etc. if configured

Pick the **HIGHEST PRIORITY** incomplete item.

---

## Phase 2: Implement

Implement the selected spec/task completely.

---

## Phase 3: Validate

Run tests and verify acceptance criteria.

---

## Phase 4: Commit & Update

1. Mark the spec/task as complete
2. `git add -A`
3. `git commit`
4. `git push`

---

## Completion Signal

**CRITICAL:** Only output the magic phrase when the work is 100% complete.

**If ALL checks pass, output:** `<promise>DONE</promise>`
"@
    $buildPrompt | Set-Content (Join-Path $PROJECT_DIR "PROMPT_build.md")

    # Planning prompt
    if (-not (Test-Path (Join-Path $PROJECT_DIR "PROMPT_plan.md"))) {
@"
# Ralph Planning Mode (OPTIONAL)

## Phase 1: Gap Analysis
## Phase 2: Create Plan

## Completion Signal
`<promise>DONE</promise>`
"@ | Set-Content (Join-Path $PROJECT_DIR "PROMPT_plan.md")
    }
}

function Get-YoloState {
    $yolo = $true
    if (Test-Path $CONSTITUTION) {
        if (Select-String -Path $CONSTITUTION -Pattern "YOLO Mode.*DISABLED" -Quiet) {
            $yolo = $false
        }
    }
    return $yolo
}
