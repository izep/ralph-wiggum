$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

function Show-CopilotHelp {
    @"
Ralph Loop for GitHub Copilot CLI

Usage:
  .\scripts\ralph-loop-copilot.ps1              # Build mode, unlimited
  .\scripts\ralph-loop-copilot.ps1 20           # Build mode, max 20 iterations
  .\scripts\ralph-loop-copilot.ps1 plan         # Planning mode (OPTIONAL)
  .\scripts\ralph-loop-copilot.ps1 --rlm-context .\rlm\context.txt
  .\scripts\ralph-loop-copilot.ps1 --rlm .\rlm\context.txt

Modes:
  build (default)  Pick incomplete spec and implement
  plan             Create IMPLEMENTATION_PLAN.md (OPTIONAL)

RLM workspace (when enabled):
  - rlm/trace/     Prompt snapshots + outputs per iteration
  - rlm/index.tsv  Index of all iterations (timestamp, prompt, log, status)
  - rlm/queries/ and rlm/answers/  For optional recursive sub-queries
"@ | Write-Host
}

$copilotCmd = if ($env:COPILOT_CMD) { $env:COPILOT_CMD } else { "copilot" }

$missingCli = @"
Error: GitHub Copilot CLI not found

Install one of these AI coding CLIs:

1. GitHub Copilot CLI (recommended for this script):
   npm install -g @github/copilot-cli
   See: https://github.com/features/copilot

2. Claude Code CLI:
   https://claude.ai/code
   Run with: ./scripts/ralph-loop.sh or .\scripts\ralph-loop.ps1

3. Google Gemini CLI:
   npm install -g @google/gemini-cli
   Run with: ./scripts/ralph-loop-gemini.sh or .\scripts\ralph-loop-gemini.ps1

4. OpenAI Codex CLI:
   npm install -g @openai/codex
   Run with: ./scripts/ralph-loop-codex.sh or .\scripts\ralph-loop-codex.ps1
"@

$config = @{
    AgentName = "Copilot"
    DisplayName = "              RALPH LOOP (GitHub Copilot) STARTING          "
    SessionPrefix = "ralph_copilot"
    Command = $copilotCmd
    PromptMode = "Argument"
    PromptArgumentSwitch = "-p"
    SupportsYolo = $true
    YoloFlag = "--yolo"
    HelpCallback = { Show-CopilotHelp }
    MissingCliMessage = $missingCli
}

Invoke-RalphLoop -Config $config -Args $args
