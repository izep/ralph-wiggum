# Date Utilities for Ralph Loop
# PowerShell version

function Get-IsoTimestamp {
    Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"
}

function Get-EpochSeconds {
    [DateTimeOffset]::Now.ToUnixTimeSeconds()
}

function Get-NextHourTime {
    $nextHour = (Get-Date).AddHours(1).Hour
    "{0:D2}:00" -f $nextHour
}

# Export functions is not strictly needed in PS but we can use Export-ModuleMember if it were a module
