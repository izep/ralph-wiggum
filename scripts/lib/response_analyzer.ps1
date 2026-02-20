# Response Analyzer for Ralph Loop
# PowerShell version

# Load shared date helpers for timestamps
$script:ResponseAnalyzerRoot = Split-Path -Parent $PSCommandPath
if (-not $script:ResponseAnalyzerRoot) {
    $script:ResponseAnalyzerRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
. (Join-Path $script:ResponseAnalyzerRoot "date_utils.ps1")

# Configuration
$COMPLETION_KEYWORDS = @("done", "complete", "finished", "all tasks complete", "project complete", "<promise>DONE</promise>", "<promise>ALL_DONE</promise>")

# Colors
$esc = [char]27
$RED = "$esc[0;31m"
$GREEN = "$esc[0;32m"
$YELLOW = "$esc[1;33m"
$BLUE = "$esc[0;34m"
$NC = "$esc[0m"

function Analyze-Response {
    param($outputFile, $loopNumber, $analysisFile = ".response_analysis")

    if (-not (Test-Path $outputFile)) {
        Write-Error "ERROR: Output file not found: $outputFile"
        return $true # Continue loop
    }

    $outputContent = Get-Content $outputFile -Raw
    $outputLength = $outputContent.Length

    # Initialize analysis values
    $hasCompletionSignal = $false
    $hasPromiseDone = $false
    $hasPromiseAllDone = $false
    $filesModified = 0
    $hasErrors = $false
    $confidenceScore = 0
    $workSummary = ""

    # 1. Check for explicit <promise>DONE</promise> or <promise>ALL_DONE</promise>
    if ($outputContent -match "<promise>DONE</promise>") {
        $hasPromiseDone = $true
        $hasCompletionSignal = $true
        $confidenceScore = 100
        $workSummary = "Explicit DONE promise detected"
    }

    if ($outputContent -match "<promise>ALL_DONE</promise>") {
        $hasPromiseAllDone = $true
        $hasCompletionSignal = $true
        $confidenceScore = 100
        $workSummary = "All items complete - ALL_DONE promise detected"
    }

    # 2. Check for completion keywords in natural language
    if (-not $hasCompletionSignal) {
        foreach ($keyword in $COMPLETION_KEYWORDS) {
            if ($outputContent -match [regex]::Escape($keyword)) {
                $hasCompletionSignal = $true
                $confidenceScore += 20
                break
            }
        }
    }

    # 3. Check for file changes via git
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $diff = git diff --name-only 2>$null
        $filesModified = ($diff | Measure-Object).Count
        if ($filesModified -gt 0) {
            $confidenceScore += 20
        }
    }

    # 4. Check for errors in output
    $errorLines = $outputContent -split "`n" | Where-Object { $_ -match "error|exception|fatal|failed" }
    $errorCount = $errorLines.Count
    if ($errorCount -gt 5) {
        $hasErrors = $true
    }

    # 5. Extract summary from output
    if ([string]::IsNullOrEmpty($workSummary)) {
        $summaryLine = $outputContent -split "`n" | Where-Object { $_ -match "summary|completed|implemented" } | Select-Object -First 1
        if ($summaryLine) {
            $workSummary = $summaryLine.Substring(0, [Math]::Min(100, $summaryLine.Length))
        } else {
            $workSummary = "Output analyzed"
        }
    }

    # Write analysis result to file
    $analysis = @{
        loop_number = $loopNumber
        timestamp = (Get-IsoTimestamp)
        output_file = $outputFile
        analysis = @{
            has_completion_signal = $hasCompletionSignal
            has_promise_done = $hasPromiseDone
            has_promise_all_done = $hasPromiseAllDone
            files_modified = $filesModified
            has_errors = $hasErrors
            confidence_score = $confidenceScore
            output_length = $outputLength
            work_summary = $workSummary
        }
    }
    $analysis | ConvertTo-Json | Set-Content $analysisFile

    # Return based on completion detection
    if ($hasPromiseDone -or $hasPromiseAllDone) {
        return $false # Stop loop
    }

    return $true # Continue loop
}

function Log-AnalysisSummary {
    param($analysisFile = ".response_analysis")

    if (-not (Test-Path $analysisFile)) {
        return
    }

    try {
        $analysis = Get-Content $analysisFile | ConvertFrom-Json
        $data = $analysis.analysis

        Write-Host "${BLUE}?---------------------------------------------------?${NC}"
        Write-Host "${BLUE}  Response Analysis - Loop #$($analysis.loop_number)${NC}"
        Write-Host "${BLUE}?---------------------------------------------------?${NC}"
        Write-Host "${YELLOW}DONE Promise:${NC}     $($data.has_promise_done)"
        Write-Host "${YELLOW}ALL_DONE:${NC}         $($data.has_promise_all_done)"
        Write-Host "${YELLOW}Confidence:${NC}       $($data.confidence_score)%"
        Write-Host "${YELLOW}Files Changed:${NC}    $($data.files_modified)"
        Write-Host "${YELLOW}Summary:${NC}          $($data.work_summary)"
        Write-Host ""
    } catch { }
}
