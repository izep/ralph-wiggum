$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

function Show-CodexHelp {
    @"
Ralph Loop for OpenAI Codex CLI

Usage:
  .\scripts\ralph-loop-codex.ps1              # Build mode, unlimited
  .\scripts\ralph-loop-codex.ps1 20           # Build mode, max 20 iterations
  .\scripts\ralph-loop-codex.ps1 plan         # Planning mode (OPTIONAL)
  .\scripts\ralph-loop-codex.ps1 --rlm-context .\rlm\context.txt
  .\scripts\ralph-loop-codex.ps1 --rlm .\rlm\context.txt

YOLO Mode: Uses --dangerously-bypass-approvals-and-sandbox when enabled.
"@ | Write-Host
}

$codexCmd = if ($env:CODEX_CMD) { $env:CODEX_CMD } else { "codex" }

$missingCli = @"
Error: Codex CLI not found

Install one of these AI coding CLIs:

1. OpenAI Codex CLI (recommended for this script):
   npm install -g @openai/codex
   Then: codex login

2. Claude Code CLI:
   https://claude.ai/code
   Run with: ./scripts/ralph-loop.sh or .\scripts\ralph-loop.ps1

3. GitHub Copilot CLI:
   npm install -g @github/copilot-cli
   Run with: ./scripts/ralph-loop-copilot.sh or .\scripts\ralph-loop-copilot.ps1

4. Google Gemini CLI:
   npm install -g @google/gemini-cli
   Run with: ./scripts/ralph-loop-gemini.sh or .\scripts\ralph-loop-gemini.ps1
"@

$config = @{
    AgentName = "Codex"
    DisplayName = "              RALPH LOOP (Codex) STARTING                    "
    SessionPrefix = "ralph_codex"
    Command = $codexCmd
    PromptMode = "Pipe"
    BaseFlags = @("exec")
    PipeArgument = "-"
    SupportsYolo = $true
    YoloFlag = "--dangerously-bypass-approvals-and-sandbox"
    OutputFileRole = "LastMessage"
    OutputFileArgument = "--output-last-message"
    HelpCallback = { Show-CodexHelp }
    MissingCliMessage = $missingCli
}

Invoke-RalphLoop -Config $config -Args $args
