$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

function Show-GeminiHelp {
    @"
Ralph Loop for Google Gemini CLI

Usage:
  .\scripts\ralph-loop-gemini.ps1              # Build mode, unlimited
  .\scripts\ralph-loop-gemini.ps1 20           # Build mode, max 20 iterations
  .\scripts\ralph-loop-gemini.ps1 plan         # Planning mode (OPTIONAL)
  .\scripts\ralph-loop-gemini.ps1 --rlm-context .\rlm\context.txt
  .\scripts\ralph-loop-gemini.ps1 --rlm .\rlm\context.txt
"@ | Write-Host
}

$geminiCmd = if ($env:GEMINI_CMD) { $env:GEMINI_CMD } else { "gemini" }

$missingCli = @"
Error: Gemini CLI not found

Install one of these AI coding CLIs:

1. Google Gemini CLI (recommended for this script):
   npm install -g @google/gemini-cli
   See: https://github.com/google-gemini/gemini-cli

2. Claude Code CLI:
   https://claude.ai/code
   Run with: ./scripts/ralph-loop.sh or .\scripts\ralph-loop.ps1

3. GitHub Copilot CLI:
   npm install -g @github/copilot-cli
   Run with: ./scripts/ralph-loop-copilot.sh or .\scripts\ralph-loop-copilot.ps1

4. OpenAI Codex CLI:
   npm install -g @openai/codex
   Run with: ./scripts/ralph-loop-codex.sh or .\scripts\ralph-loop-codex.ps1
"@

$config = @{
    AgentName = "Gemini"
    DisplayName = "              RALPH LOOP (Google Gemini) STARTING            "
    SessionPrefix = "ralph_gemini"
    Command = $geminiCmd
    PromptMode = "Argument"
    PromptArgumentSwitch = "-p"
    SupportsYolo = $true
    YoloFlag = "--yolo"
    HelpCallback = { Show-GeminiHelp }
    MissingCliMessage = $missingCli
}

Invoke-RalphLoop -Config $config -Args $args
