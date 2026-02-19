# Ralph Wiggum NR_OF_TRIES Tracking Library
# PowerShell version

$script:MAX_NR_OF_TRIES = if ($env:MAX_NR_OF_TRIES) { [int]$env:MAX_NR_OF_TRIES } else { 10 }

function Get-NrOfTries {
    param($specFile)
    if (Test-Path $specFile) {
        $content = Get-Content $specFile -Raw
        if ($content -match 'NR_OF_TRIES:\s*(?<tries>\d+)') {
            return [int]$Matches.tries
        }
    }
    return 0
}

function Increment-NrOfTries {
    param($specFile)
    $currentTries = Get-NrOfTries $specFile
    $newTries = $currentTries + 1
    
    $content = Get-Content $specFile -Raw
    if ($content -match 'NR_OF_TRIES:\s*\d+') {
        $content = $content -replace 'NR_OF_TRIES:\s*\d+', "NR_OF_TRIES: $newTries"
    } else {
        $content += "`n<!-- NR_OF_TRIES: $newTries -->"
    }
    $content | Set-Content $specFile
    
    return $newTries
}

function Reset-NrOfTries {
    param($specFile)
    if (Test-Path $specFile) {
        $content = Get-Content $specFile -Raw
        if ($content -match 'NR_OF_TRIES:\s*\d+') {
            $content = $content -replace 'NR_OF_TRIES:\s*\d+', "NR_OF_TRIES: 0"
            $content | Set-Content $specFile
        }
    }
}

function Test-IsSpecStuck {
    param($specFile)
    $tries = Get-NrOfTries $specFile
    return $tries -ge $script:MAX_NR_OF_TRIES
}

function Get-StuckSpecs {
    param($specsDir = "specs")
    $stuckSpecs = @()
    if (Test-Path $specsDir) {
        $files = Get-ChildItem -Path $specsDir -Filter "*.md" -Recurse
        foreach ($file in $files) {
            if (Test-IsSpecStuck $file.FullName) {
                $stuckSpecs += $file.FullName
            }
        }
    }
    return $stuckSpecs
}

function Print-StuckSpecsSummary {
    param($specsDir = "specs")
    $stuckSpecs = Get-StuckSpecs $specsDir
    if ($stuckSpecs.Count -gt 0) {
        Write-Host "?? Stuck Specs (>= $script:MAX_NR_OF_TRIES attempts):"
        foreach ($spec in $stuckSpecs) {
            $tries = Get-NrOfTries $spec
            Write-Host "  - $spec ($tries attempts)"
        }
        Write-Host ""
        Write-Host "Consider splitting these specs into smaller, more achievable tasks."
    }
}
