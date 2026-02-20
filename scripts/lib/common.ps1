# Common utilities for Ralph Loop PowerShell scripts

$global:PROJECT_DIR = Resolve-Path "$PSScriptRoot\..\.."
$global:LOG_DIR = Join-Path $PROJECT_DIR "logs"
$global:CONSTITUTION = Join-Path $PROJECT_DIR ".specify\memory\constitution.md"
$global:RLM_DIR = Join-Path $PROJECT_DIR "rlm"
$global:RLM_TRACE_DIR = Join-Path $RLM_DIR "trace"
$global:RLM_QUERIES_DIR = Join-Path $RLM_DIR "queries"
$global:RLM_ANSWERS_DIR = Join-Path $RLM_DIR "answers"
$global:RLM_INDEX = Join-Path $RLM_DIR "index.tsv"

$esc = [char]27
$global:RED = "$esc[0;31m"
$global:GREEN = "$esc[0;32m"
$global:YELLOW = "$esc[1;33m"
$global:BLUE = "$esc[0;34m"
$global:PURPLE = "$esc[0;35m"
$global:CYAN = "$esc[0;36m"
$global:NC = "$esc[0m"

function Initialize-Ralph {
    param(
        [string]$Mode,
        [string]$RlmContextFile
    )

    if (-not (Test-Path $LOG_DIR)) {
        New-Item -ItemType Directory -Path $LOG_DIR -Force > $null
    }

    $buildPrompt = @'
# Ralph Build Mode

Based on Geoffrey Huntley's Ralph Wiggum methodology.

---

## Phase 0: Orient

Read `.specify/memory/constitution.md` to understand project principles and constraints.

---

## Phase 1: Discover Work Items

Search for incomplete work from these sources (in order):

1. **specs/ folder** — Look for `.md` files NOT marked `## Status: COMPLETE`
2. **IMPLEMENTATION_PLAN.md** — If exists, find unchecked `- [ ]` tasks
3. **GitHub Issues** — Check for open issues (if this is a GitHub repo)
4. **Any task tracker** — Jira, Linear, etc. if configured

Pick the **HIGHEST PRIORITY** incomplete item:
- Lower numbers = higher priority (001 before 010)
- `[HIGH]` before `[MEDIUM]` before `[LOW]`
- Bugs/blockers before features

Before implementing, search the codebase to verify it's not already done.

---

## Phase 1b: Re-Verification Mode (No Incomplete Work Found)

**If ALL specs appear complete**, don't just exit — do a quality check:

1. **Randomly pick** one completed spec from `specs/`
2. **Strictly re-verify** ALL its acceptance criteria:
   - Run the actual tests mentioned in the spec
   - Manually verify each criterion is truly met
   - Check edge cases
   - Look for regressions
3. **If any criterion fails**: Unmark the spec as complete and fix it
4. **If all pass**: Output `<promise>DONE</promise>` to confirm quality

This ensures the codebase stays healthy even when "nothing to do."

---

## Phase 2: Implement

Implement the selected spec/task completely:
- Follow the spec's requirements exactly
- Write clean, maintainable code
- Add tests as needed

---

## Phase 3: Validate

Run the project's test suite and verify:
- All tests pass
- No lint errors
- The spec's acceptance criteria are 100% met

---

## Phase 4: Commit & Update

1. Mark the spec/task as complete (add `## Status: COMPLETE` to spec file)
2. `git add -A`
3. `git commit` with a descriptive message
4. `git push`

---

## Completion Signal

**CRITICAL:** Only output the magic phrase when the work is 100% complete.

Check:
- [ ] Implementation matches all requirements
- [ ] All tests pass
- [ ] All acceptance criteria verified
- [ ] Changes committed and pushed
- [ ] Spec marked as complete

**If ALL checks pass, output:** `<promise>DONE</promise>`

**If ANY check fails:** Fix the issue and try again. Do NOT output the magic phrase.
'@

    if (-not [string]::IsNullOrEmpty($RlmContextFile)) {
        $buildPrompt += @'

## Phase 0d: RLM Context (Optional)

You can optionally work with a large context file as an external environment.
Treat it like an on-disk memory store: search, slice, and stream results instead
of loading the entire file into the prompt.

---
'@
    }

    Set-Content -Path (Join-Path $PROJECT_DIR "PROMPT_build.md") -Value $buildPrompt -Encoding UTF8

    $planPrompt = @'
# Ralph Planning Mode (OPTIONAL)

This mode is OPTIONAL. Most projects work fine directly from specs.

Only use this when you want a detailed breakdown of specs into smaller tasks.

---

## Phase 0: Orient

0a. Read `.specify/memory/constitution.md` for project principles.

0b. Study `specs/` to learn all feature specifications.

---

## Phase 1: Gap Analysis

Compare specs against current codebase:
- What's fully implemented?
- What's partially done?
- What's not started?
- What has issues or bugs?

---

## Phase 2: Create Plan

Create `IMPLEMENTATION_PLAN.md` with a prioritized task list:

```
# Implementation Plan

> Auto-generated breakdown of specs into tasks.
> Delete this file to return to working directly from specs.

## Priority Tasks

- [ ] [HIGH] Task description - from spec NNN
- [ ] [HIGH] Task description - from spec NNN
- [ ] [MEDIUM] Task description
- [ ] [LOW] Task description

## Completed

- [x] Completed task
```

Prioritize by:
1. Dependencies (do prerequisites first)
2. Impact (high-value features first)
3. Complexity (mix easy wins with harder tasks)

---

## Completion Signal

When the plan is complete and saved:

`<promise>DONE</promise>`
'@

    if (-not [string]::IsNullOrEmpty($RlmContextFile)) {
        $planPrompt += @'

## Phase 0c: RLM Context (Optional)

If you are using an external context file, inspect only the slices you need
instead of dumping the entire file into the prompt. Treat it as a searchable
knowledge base.
'@
    }

    Set-Content -Path (Join-Path $PROJECT_DIR "PROMPT_plan.md") -Value $planPrompt -Encoding UTF8
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

function Parse-RalphArgs {
    param([string[]]$Args)

    $inputArgs = @()
    if ($PSBoundParameters.ContainsKey('Args') -and $PSBoundParameters['Args']) {
        $inputArgs = [string[]]$PSBoundParameters['Args']
    }

    $mode = "build"
    $maxIterations = 0
    $rlmContextFile = ""
    $showHelp = $false

    for ($i = 0; $i -lt $inputArgs.Length; $i++) {
        $arg = $inputArgs[$i]
        switch -Regex ($arg) {
            '^plan$' {
                $mode = "plan"
                if ($i + 1 -lt $inputArgs.Length -and $inputArgs[$i + 1] -match '^[0-9]+$') {
                    $maxIterations = [int]$inputArgs[$i + 1]
                    $i++
                } else {
                    $maxIterations = 1
                }
            }
            '^--rlm-context$' {
                if ($i + 1 -ge $inputArgs.Length) {
                    throw "Error: --rlm-context requires a file path"
                }
                $rlmContextFile = $inputArgs[$i + 1]
                $i++
            }
            '^--rlm$' {
                if ($i + 1 -lt $inputArgs.Length -and $inputArgs[$i + 1] -notmatch '^-') {
                    $rlmContextFile = $inputArgs[$i + 1]
                    $i++
                } else {
                    $rlmContextFile = "rlm/context.txt"
                }
            }
            '^(?:-h|--help)$' {
                $showHelp = $true
            }
            '^[0-9]+$' {
                $mode = "build"
                $maxIterations = [int]$arg
            }
            default {
                throw "Unknown argument: $arg"
            }
        }
    }

    [pscustomobject]@{
        Mode = $mode
        MaxIterations = $maxIterations
        RlmContextFile = $rlmContextFile
        ShowHelp = $showHelp
    }
}

function Print-LatestOutput {
    param(
        [string]$LogFile,
        [string]$Label,
        [int]$Lines = 5
    )

    if (-not (Test-Path $LogFile)) {
        return
    }

    Write-Host "Latest $Label output (last $Lines lines):"
    try {
        Get-Content -Path $LogFile -Tail $Lines | ForEach-Object { Write-Host $_ }
    } catch {
        # ignore tail errors
    }
}

function Get-RlmContextBlock {
    param([string]$ContextPath)

    $block = @'

---
## RLM Context (Optional)

You have access to a large context file at:
**__CONTEXT__**

Treat this file as an external environment. Do NOT paste the whole file into the prompt.
Instead, inspect it programmatically and recursively:

- Use small slices:
  ```bash
  sed -n 'START,ENDp' "__CONTEXT__"
  ```
- Or Python snippets:
  ```bash
  python - <<'PY'
  from pathlib import Path
  p = Path("__CONTEXT__")
  print(p.read_text().splitlines()[START:END])
  PY
  ```
- Use search:
  ```bash
  rg -n "pattern" "__CONTEXT__"
  ```

Goal: decompose the task into smaller sub-queries and only load the pieces you need.
This mirrors the Recursive Language Model approach from https://arxiv.org/html/2512.24601v1

## RLM Workspace (Optional)

Past loop outputs are preserved on disk:
- Iteration logs: `logs/`
- Prompt/output snapshots: `rlm/trace/`
- Iteration index: `rlm/index.tsv`

Use these as an external memory store (search/slice as needed).
If you need a recursive sub-query, write a focused prompt in `rlm/queries/`,
then run one of:

- macOS/Linux: `./scripts/rlm-subcall.sh --query rlm/queries/<file>.md`
- Windows (PowerShell): `pwsh -NoProfile -File .\scripts\rlm-subcall.ps1 --query .\rlm\queries\<file>.md`

Store the result in `rlm/answers/`.
'@

    return $block.Replace('__CONTEXT__', $ContextPath)
}

function Invoke-RalphLoop {
    param(
        [hashtable]$Config,
        [string[]]$Args
    )

    $inputArgs = @()
    if ($PSBoundParameters.ContainsKey('Args') -and $PSBoundParameters['Args']) {
        $inputArgs = [string[]]$PSBoundParameters['Args']
    }

    $required = @("AgentName", "DisplayName", "SessionPrefix", "Command", "PromptMode", "HelpCallback", "MissingCliMessage")
    foreach ($key in $required) {
        if (-not $Config.ContainsKey($key)) {
            throw "Invoke-RalphLoop missing configuration value: $key"
        }
    }

    $parsed = Parse-RalphArgs -Args $inputArgs
    if ($parsed.ShowHelp) {
        & $Config.HelpCallback
        return
    }

    $mode = $parsed.Mode
    $maxIterations = $parsed.MaxIterations
    if ($mode -eq "plan" -and $maxIterations -eq 0) {
        $maxIterations = 1
    }

    $rlmContextFile = $parsed.RlmContextFile

    $cliCommand = $Config.Command
    if (-not $cliCommand) {
        $cliCommand = $Config.AgentName
    }

    if (-not (Get-Command $cliCommand -ErrorAction SilentlyContinue)) {
        Write-Host $Config.MissingCliMessage
        return
    }

    $tailLines = if ($Config.ContainsKey('TailLines')) { $Config.TailLines } else { 5 }
    $baseFlags = @()
    if ($Config.ContainsKey('BaseFlags') -and $Config.BaseFlags) {
        $baseFlags += $Config.BaseFlags
    }
    $supportsYolo = $Config.ContainsKey('SupportsYolo') -and $Config.SupportsYolo
    $promptArgumentSwitch = if ($Config.ContainsKey('PromptArgumentSwitch')) { $Config.PromptArgumentSwitch } else { $null }
    $pipeArgument = if ($Config.ContainsKey('PipeArgument')) { $Config.PipeArgument } else { $null }
    $outputFileRole = if ($Config.ContainsKey('OutputFileRole')) { $Config.OutputFileRole } else { "None" }
    $outputFileArgument = if ($Config.ContainsKey('OutputFileArgument')) { $Config.OutputFileArgument } else { $null }

    Push-Location $PROJECT_DIR

    try {
        Initialize-Ralph -Mode $mode -RlmContextFile $rlmContextFile
        $yoloEnabled = Get-YoloState

        $resolvedRlmContextFile = ""
        if (-not [string]::IsNullOrEmpty($rlmContextFile)) {
            if (-not (Test-Path $rlmContextFile)) {
                throw "Error: RLM context file not found: $rlmContextFile"
            }
            $resolvedRlmContextFile = (Resolve-Path $rlmContextFile).Path
            New-Item -ItemType Directory -Path $RLM_TRACE_DIR, $RLM_QUERIES_DIR, $RLM_ANSWERS_DIR -Force > $null
            if (-not (Test-Path $RLM_INDEX)) {
                "timestamp`tmode`titeration`tprompt`tlog`toutput`tstatus" | Set-Content -Path $RLM_INDEX -Encoding UTF8
            }
        }

        $sessionTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $sessionLog = Join-Path $LOG_DIR ("{0}_{1}_session_{2}.log" -f $Config.SessionPrefix, $mode, $sessionTimestamp)
        $transcriptStarted = $false

        try {
            Start-Transcript -Path $sessionLog -Append | Out-Null
            $transcriptStarted = $true

            $currentBranch = (git branch --show-current 2>$null)
            if (-not $currentBranch) { $currentBranch = "main" }

            $hasPlan = Test-Path "IMPLEMENTATION_PLAN.md"
            $specCount = 0
            $hasSpecs = $false
            if (Test-Path "specs") {
                $specCount = (Get-ChildItem -Path "specs" -Filter '*.md' -File | Measure-Object).Count
                if ($specCount -gt 0) { $hasSpecs = $true }
            }

            $promptFile = if ($mode -eq "plan") { "PROMPT_plan.md" } else { "PROMPT_build.md" }

            $cliFlags = @()
            if ($baseFlags) { $cliFlags += $baseFlags }
            if ($supportsYolo -and $yoloEnabled -and $Config.ContainsKey('YoloFlag') -and $Config.YoloFlag) {
                $cliFlags += $Config.YoloFlag
            }

            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host ($Config.DisplayName) -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host ""
            Write-Host ("Mode:     {0}" -f $mode) -ForegroundColor Blue
            Write-Host ("Prompt:   {0}" -f $promptFile) -ForegroundColor Blue
            Write-Host ("Branch:   {0}" -f $currentBranch) -ForegroundColor Blue
            Write-Host ("YOLO:     {0}" -f ($(if ($yoloEnabled) { "ENABLED" } else { "DISABLED" }))) -ForegroundColor Yellow
            if ($resolvedRlmContextFile) {
                Write-Host ("RLM:      {0}" -f $resolvedRlmContextFile) -ForegroundColor Blue
            }
            Write-Host ("Log:      {0}" -f $sessionLog) -ForegroundColor Blue
            if ($maxIterations -gt 0) {
                Write-Host ("Max:      {0} iterations" -f $maxIterations) -ForegroundColor Blue
            }
            Write-Host ""
            Write-Host "Work source:" -ForegroundColor Blue
            if ($hasPlan) {
                Write-Host "  ✓ IMPLEMENTATION_PLAN.md (will use this)" -ForegroundColor Green
            } else {
                Write-Host "  ○ IMPLEMENTATION_PLAN.md (not found, that's OK)" -ForegroundColor Yellow
            }
            if ($hasSpecs) {
                Write-Host ("  ✓ specs/ folder ({0} specs)" -f $specCount) -ForegroundColor Green
            } else {
                Write-Host "  ✗ specs/ folder (no .md files found)" -ForegroundColor Red
            }
            Write-Host ""
            Write-Host "The loop checks for <promise>DONE</promise> in each iteration." -ForegroundColor Cyan
            Write-Host "Agent must verify acceptance criteria before outputting it." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Press Ctrl+C to stop the loop" -ForegroundColor Yellow
            Write-Host ""

            $iteration = 0
            $consecutiveFailures = 0
            $maxConsecutiveFailures = 3

            while ($true) {
                if ($maxIterations -gt 0 -and $iteration -ge $maxIterations) {
                    Write-Host ("Reached max iterations: {0}" -f $maxIterations) -ForegroundColor Green
                    break
                }

                $iteration++
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                Write-Host ""
                Write-Host ("════════════════════ LOOP {0} ════════════════════" -f $iteration) -ForegroundColor Magenta
                Write-Host ("[{0}] Starting iteration {1}" -f $timestamp, $iteration) -ForegroundColor Blue
                Write-Host ""

                $iterationStamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $logFile = Join-Path $LOG_DIR ("{0}_{1}_iter_{2}_{3}.log" -f $Config.SessionPrefix, $mode, $iteration, $iterationStamp)
                $rlmStatus = "unknown"
                $rlmPromptSnapshot = $null
                $rlmOutputSnapshot = $null
                $rlmLastMessageSnapshot = $null

                $effectivePromptFile = $promptFile
                if ($resolvedRlmContextFile) {
                    $effectivePromptFile = Join-Path $LOG_DIR ("{0}_prompt_iter_{1}_{2}.md" -f $Config.SessionPrefix, $iteration, $iterationStamp)
                    Copy-Item -Path $promptFile -Destination $effectivePromptFile -Force
                    Add-Content -Path $effectivePromptFile -Value (Get-RlmContextBlock -ContextPath $resolvedRlmContextFile)
                    $rlmPromptSnapshot = Join-Path $RLM_TRACE_DIR ("iter_{0}_prompt.md" -f $iteration)
                    Copy-Item -Path $effectivePromptFile -Destination $rlmPromptSnapshot -Force
                }

                $promptContent = Get-Content -Path $effectivePromptFile -Raw

                $outputFile = $null
                if ($outputFileRole -eq "LastMessage") {
                    $outputFile = Join-Path $LOG_DIR ("{0}_output_iter_{1}_{2}.txt" -f $Config.SessionPrefix, $iteration, $iterationStamp)
                    if (Test-Path $outputFile) { Remove-Item $outputFile -Force }
                }

                $commandOutput = $null
                $success = $false

                if ($Config.PromptMode -eq "Pipe") {
                    $argsList = @()
                    if ($cliFlags) { $argsList += $cliFlags }
                    if ($pipeArgument) { $argsList += $pipeArgument }
                    if ($outputFileRole -eq "LastMessage" -and $outputFileArgument -and $outputFile) {
                        $argsList += @($outputFileArgument, $outputFile)
                    }

                    $result = $promptContent | & $cliCommand @argsList 2>&1 | Tee-Object -FilePath $logFile
                    $commandOutput = ($result | Out-String)
                    $success = ($LASTEXITCODE -eq 0)
                } elseif ($Config.PromptMode -eq "Argument") {
                    $argsList = @()
                    if ($cliFlags) { $argsList += $cliFlags }
                    if ($promptArgumentSwitch) {
                        $argsList += $promptArgumentSwitch
                    }
                    $argsList += $promptContent

                    $result = & $cliCommand @argsList 2>&1 | Tee-Object -FilePath $logFile
                    $commandOutput = ($result | Out-String)
                    $success = ($LASTEXITCODE -eq 0)
                } else {
                    throw "Unsupported PromptMode: $($Config.PromptMode)"
                }

                if ($success) {
                    Write-Host ""
                    Write-Host "✓ Agent execution completed" -ForegroundColor Green
                } else {
                    Write-Host "✗ Agent execution failed" -ForegroundColor Red
                }

                $completionDetected = $false
                $detectedSignal = $null

                if ($outputFile -and (Test-Path $outputFile)) {
                    $outputContent = Get-Content -Path $outputFile -Raw
                    $match = [regex]::Match($outputContent, "<promise>(ALL_)?DONE</promise>")
                    if ($match.Success) {
                        $completionDetected = $true
                        $detectedSignal = $match.Value
                    }
                }

                if (-not $completionDetected -and $commandOutput) {
                    $match = [regex]::Match($commandOutput, "<promise>(ALL_)?DONE</promise>")
                    if ($match.Success) {
                        $completionDetected = $true
                        $detectedSignal = $match.Value
                    }
                }

                if ($success -and $completionDetected) {
                    Write-Host ("✓ Completion signal detected: {0}" -f $detectedSignal) -ForegroundColor Green
                    Write-Host "✓ Task completed successfully!" -ForegroundColor Green
                    $consecutiveFailures = 0
                    $rlmStatus = "done"

                    if ($mode -eq "plan") {
                        Write-Host ""
                        Write-Host "Planning complete!" -ForegroundColor Green
                        Write-Host "Run './scripts/ralph-loop.sh' or '.\scripts\ralph-loop.ps1' to start building." -ForegroundColor Cyan
                        break
                    }
                } elseif ($success) {
                    Write-Host "⚠ No completion signal found" -ForegroundColor Yellow
                    Write-Host "  Agent did not output <promise>DONE</promise> or <promise>ALL_DONE</promise>" -ForegroundColor Yellow
                    Write-Host "  Retrying in next iteration..." -ForegroundColor Yellow
                    $consecutiveFailures++
                    $rlmStatus = "incomplete"
                    Print-LatestOutput -LogFile $logFile -Label $Config.AgentName -Lines $tailLines

                    if ($consecutiveFailures -ge $maxConsecutiveFailures) {
                        Write-Host ""
                        Write-Host ("⚠ {0} consecutive iterations without completion." -f $maxConsecutiveFailures) -ForegroundColor Red
                        Write-Host "  The agent may be stuck. Check the logs." -ForegroundColor Red
                        $consecutiveFailures = 0
                    }
                } else {
                    Write-Host "Execution failed; see log for details." -ForegroundColor Red
                    $consecutiveFailures++
                    $rlmStatus = "error"
                    Print-LatestOutput -LogFile $logFile -Label $Config.AgentName -Lines $tailLines
                }

                if ($resolvedRlmContextFile) {
                    $rlmOutputSnapshot = Join-Path $RLM_TRACE_DIR ("iter_{0}_output.log" -f $iteration)
                    Copy-Item -Path $logFile -Destination $rlmOutputSnapshot -Force
                    if ($outputFile -and (Test-Path $outputFile)) {
                        $rlmLastMessageSnapshot = Join-Path $RLM_TRACE_DIR ("iter_{0}_last_message.txt" -f $iteration)
                        Copy-Item -Path $outputFile -Destination $rlmLastMessageSnapshot -Force
                    }

                    $promptForIndex = if ($rlmPromptSnapshot) { $rlmPromptSnapshot } else { "" }
                    $outputForIndex = if ($rlmLastMessageSnapshot) { $rlmLastMessageSnapshot } else { $rlmOutputSnapshot }
                    $indexLine = "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $timestamp, $mode, $iteration, $promptForIndex, $logFile, $outputForIndex, $rlmStatus
                    Add-Content -Path $RLM_INDEX -Value $indexLine
                }

                git push origin $currentBranch 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    $ahead = git log "origin/$currentBranch..HEAD" --oneline 2>$null
                    if ($LASTEXITCODE -eq 0 -and $ahead) {
                        git push -u origin $currentBranch 2>$null | Out-Null
                    }
                }

                Write-Host ""
                Write-Host "Waiting 2s before next iteration..." -ForegroundColor Blue
                Start-Sleep -Seconds 2
            }

            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
            Write-Host ("         Loop finished ({0} iterations)         " -f $iteration) -ForegroundColor Green
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        } finally {
            if ($transcriptStarted) {
                Stop-Transcript | Out-Null
            }
        }
    } finally {
        Pop-Location
    }
}
