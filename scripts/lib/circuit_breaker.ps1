# Circuit Breaker for Ralph Loop
# PowerShell version

# Import dependencies
. "$PSScriptRoot\date_utils.ps1"

# Circuit Breaker States
$CB_STATE_CLOSED = "CLOSED"
$CB_STATE_HALF_OPEN = "HALF_OPEN"
$CB_STATE_OPEN = "OPEN"

# Configuration
$CB_STATE_FILE = ".circuit_breaker_state"
$CB_NO_PROGRESS_THRESHOLD = 5
$CB_SAME_ERROR_THRESHOLD = 3

# Colors
$RED = "`[0;31m"
$GREEN = "`[0;32m"
$YELLOW = "`[1;33m"
$NC = "`[0m"

function Init-CircuitBreaker {
    if (-not (Test-Path $CB_STATE_FILE)) {
        $state = @{
            state = $CB_STATE_CLOSED
            last_change = (Get-IsoTimestamp)
            consecutive_no_progress = 0
            consecutive_same_error = 0
            last_progress_loop = 0
            total_opens = 0
            reason = ""
        }
        $state | ConvertTo-Json | Set-Content $CB_STATE_FILE
    }
}

function Get-CircuitState {
    if (-not (Test-Path $CB_STATE_FILE)) {
        return $CB_STATE_CLOSED
    }
    try {
        $state = Get-Content $CB_STATE_FILE | ConvertFrom-Json
        return $state.state
    } catch {
        return $CB_STATE_CLOSED
    }
}

function Test-CanExecute {
    $state = Get-CircuitState
    return $state -ne $CB_STATE_OPEN
}

function Record-LoopResult {
    param($loopNumber, $filesChanged, $hasErrors)

    Init-CircuitBreaker

    $stateData = Get-Content $CB_STATE_FILE | ConvertFrom-Json
    $currentState = $stateData.state
    $consecutiveNoProgress = [int]$stateData.consecutive_no_progress
    $consecutiveSameError = [int]$stateData.consecutive_same_error
    $lastProgressLoop = [int]$stateData.last_progress_loop
    $totalOpens = [int]$stateData.total_opens

    # Detect progress
    $hasProgress = $false
    if ($filesChanged -gt 0) {
        $hasProgress = $true
        $consecutiveNoProgress = 0
        $lastProgressLoop = $loopNumber
    } else {
        $consecutiveNoProgress++
    }

    # Track errors
    if ($hasErrors -eq "true" -or $hasErrors -eq $true) {
        $consecutiveSameError++
    } else {
        $consecutiveSameError = 0
    }

    # Determine new state
    $newState = $currentState
    $reason = ""

    switch ($currentState) {
        $CB_STATE_CLOSED {
            if ($consecutiveNoProgress -ge $CB_NO_PROGRESS_THRESHOLD) {
                $newState = $CB_STATE_OPEN
                $reason = "No progress in $consecutiveNoProgress consecutive loops"
            } elseif ($consecutiveSameError -ge $CB_SAME_ERROR_THRESHOLD) {
                $newState = $CB_STATE_OPEN
                $reason = "Same error in $consecutiveSameError consecutive loops"
            } elseif ($consecutiveNoProgress -ge 2) {
                $newState = $CB_STATE_HALF_OPEN
                $reason = "Monitoring: $consecutiveNoProgress loops without progress"
            }
        }
        $CB_STATE_HALF_OPEN {
            if ($hasProgress) {
                $newState = $CB_STATE_CLOSED
                $reason = "Progress detected, circuit recovered"
            } elseif ($consecutiveNoProgress -ge $CB_NO_PROGRESS_THRESHOLD) {
                $newState = $CB_STATE_OPEN
                $reason = "No recovery, opening circuit"
            }
        }
        $CB_STATE_OPEN {
            $reason = "Circuit is open, execution halted"
        }
    }

    # Update opens count
    if ($newState -eq $CB_STATE_OPEN -and $currentState -ne $CB_STATE_OPEN) {
        $totalOpens++
    }

    # Write updated state
    $stateData.state = $newState
    $stateData.last_change = (Get-IsoTimestamp)
    $stateData.consecutive_no_progress = $consecutiveNoProgress
    $stateData.consecutive_same_error = $consecutiveSameError
    $stateData.last_progress_loop = $lastProgressLoop
    $stateData.total_opens = $totalOpens
    $stateData.reason = $reason
    $stateData.current_loop = $loopNumber

    $stateData | ConvertTo-Json | Set-Content $CB_STATE_FILE

    # Log state transition
    if ($newState -ne $currentState) {
        switch ($newState) {
            $CB_STATE_OPEN { Write-Host "${RED}?? CIRCUIT BREAKER OPENED: $reason${NC}" }
            $CB_STATE_HALF_OPEN { Write-Host "${YELLOW}?? CIRCUIT BREAKER: Monitoring - $reason${NC}" }
            $CB_STATE_CLOSED { Write-Host "${GREEN}? CIRCUIT BREAKER: Normal Operation - $reason${NC}" }
        }
    }

    return $newState -ne $CB_STATE_OPEN
}

function Test-ShouldHaltExecution {
    $state = Get-CircuitState
    if ($state -eq $CB_STATE_OPEN) {
        Write-Host "${RED}+-----------------------------------------------------------+${NC}"
        Write-Host "${RED}¦  EXECUTION HALTED: Circuit Breaker Opened               ¦${NC}"
        Write-Host "${RED}+-----------------------------------------------------------+${NC}"
        Write-Host ""
        Write-Host "${YELLOW}Ralph detected no progress is being made.${NC}"
        Write-Host ""
        Write-Host "Possible reasons:"
        Write-Host "  • Task may be complete"
        Write-Host "  • Agent may be stuck on an error"
        Write-Host "  • Prompt needs clarification"
        Write-Host ""
        Write-Host "To continue:"
        Write-Host "  1. Review logs"
        Write-Host "  2. Fix any issues"
        Write-Host "  3. Reset circuit breaker: --reset-circuit"
        return $true
    }
    return $false
}

function Reset-CircuitBreaker {
    param($reason = "Manual reset")
    $state = @{
        state = $CB_STATE_CLOSED
        last_change = (Get-IsoTimestamp)
        consecutive_no_progress = 0
        consecutive_same_error = 0
        last_progress_loop = 0
        total_opens = 0
        reason = $reason
    }
    $state | ConvertTo-Json | Set-Content $CB_STATE_FILE
    Write-Host "${GREEN}? Circuit breaker reset to CLOSED state${NC}"
}

function Show-CircuitStatus {
    Init-CircuitBreaker
    $state = Get-Content $CB_STATE_FILE | ConvertFrom-Json
    Write-Host "${YELLOW}Circuit Breaker Status${NC}"
    Write-Host "  State: $($state.state)"
    Write-Host "  Reason: $($state.reason)"
    Write-Host "  Loops without progress: $($state.consecutive_no_progress)"
    Write-Host "  Current loop: $($state.current_loop)"
}
