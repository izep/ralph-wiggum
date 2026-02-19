# Ralph Wiggum Notifications Library
# PowerShell version

# Configuration
$TELEGRAM_ENABLED = $true
$TELEGRAM_AUDIO = $false

function Check-Telegram {
    if ([string]::IsNullOrEmpty($env:TG_BOT_TOKEN) -or [string]::IsNullOrEmpty($env:TG_CHAT_ID)) {
        $script:TELEGRAM_ENABLED = $false
    }
    if ([string]::IsNullOrEmpty($env:CHUTES_API_KEY)) {
        $script:TELEGRAM_AUDIO = $false
    }
}

function Send-Telegram {
    param($message)
    if ($script:TELEGRAM_ENABLED) {
        $url = "https://api.telegram.org/bot$($env:TG_BOT_TOKEN)/sendMessage"
        $body = @{
            chat_id = $env:TG_CHAT_ID
            parse_mode = "Markdown"
            text = $message
        }
        try {
            Invoke-RestMethod -Uri $url -Method Post -Body $body >$null
        } catch { }
    }
}

function Send-TelegramAudio {
    param($message, $caption = "Progress Update")
    if ($script:TELEGRAM_AUDIO -and $script:TELEGRAM_ENABLED) {
        $tempPath = [IO.Path]::Combine([IO.Path]::GetTempPath(), "tg_audio.wav")
        $ttsUrl = "https://chutes-kokoro.chutes.ai/speak"
        $ttsBody = @{
            text = $message
            voice = "am_michael"
            speed = 1.0
        } | ConvertTo-Json
        
        try {
            Invoke-WebRequest -Uri $ttsUrl -Method Post -ContentType "application/json" -Headers @{Authorization = "Bearer $($env:CHUTES_API_KEY)"} -Body $ttsBody -OutFile $tempPath
            
            $tgUrl = "https://api.telegram.org/bot$($env:TG_BOT_TOKEN)/sendVoice"
            # In PowerShell 5.1/7, sending multipart form data can be done via -Form or custom construction.
            # Here we'll try the simplest approach for PS 7+
            $Form = @{
                chat_id = $env:TG_CHAT_ID
                voice = Get-Item $tempPath
                caption = $caption
            }
            Invoke-RestMethod -Uri $tgUrl -Method Post -Form $Form >$null
            
            Remove-Item $tempPath -ErrorAction SilentlyContinue
        } catch { }
    }
}

function Send-TelegramImage {
    param($imagePath, $caption = "")
    if ($script:TELEGRAM_ENABLED -and (Test-Path $imagePath)) {
        $url = "https://api.telegram.org/bot$($env:TG_BOT_TOKEN)/sendPhoto"
        $Form = @{
            chat_id = $env:TG_CHAT_ID
            photo = Get-Item $imagePath
            caption = $caption
        }
        try {
            Invoke-RestMethod -Uri $url -Method Post -Form $Form >$null
        } catch { }
    }
}

function Generate-MermaidImage {
    param($mermaidCode, $outputPath)
    
    # Check for mmdc (mermaid-cli)
    if (Get-Command mmdc -ErrorAction SilentlyContinue) {
        $tempFile = [IO.Path]::GetTempFileName()
        $mermaidCode | Set-Content $tempFile
        try {
            mmdc -i $tempFile -o $outputPath 2>$null
            return $true
        } catch {
            return $false
        } finally {
            Remove-Item $tempFile -ErrorAction SilentlyContinue
        }
    } else {
        # Fallback to kroki.io
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($mermaidCode)
            $encoded = [Convert]::ToBase64String($bytes)
            $url = "https://kroki.io/mermaid/png/$encoded"
            Invoke-WebRequest -Uri $url -OutFile $outputPath >$null
            return $true
        } catch {
            return $false
        }
    }
}

function Create-CompletionLog {
    param($specName, $summary, $mermaidCode, $completionLogDir = "completion_log")
    
    if (-not (Test-Path $completionLogDir)) {
        New-Item -ItemType Directory -Path $completionLogDir -Force >$null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd--HH-mm-ss"
    $safeName = $specName -replace '[^a-zA-Z0-9_-]', '-' -replace '-+', '-'
    $logBase = Join-Path $completionLogDir "${timestamp}--${safeName}"
    
    $mdContent = @"
# Completion Log: $specName

**Timestamp:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Spec:** $specName

## Summary

$summary

## Mermaid Diagram

```mermaid
$mermaidCode
```
"@
    $mdContent | Set-Content "${logBase}.md"
    
    if (-not [string]::IsNullOrEmpty($mermaidCode)) {
        Generate-MermaidImage $mermaidCode "${logBase}.png" | Out-Null
    }
    
    return $logBase
}
