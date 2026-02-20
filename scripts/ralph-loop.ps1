$ErrorActionPreference = "Stop"

$SCRIPT_DIR = $PSScriptRoot
. (Join-Path $SCRIPT_DIR "lib\common.ps1")

function Show-ClaudeHelp {
    @"
Ralph Loop for Claude Code

Based on Geoffrey Huntley's Ralph Wiggum methodology + SpecKit specs.
https://github.com/ghuntley/how-to-ralph-wiggum

Usage:
  .\scripts\ralph-loop.ps1              # Build mode, unlimited iterations
  .\scripts\ralph-loop.ps1 20           # Build mode, max 20 iterations
  .\scripts\ralph-loop.ps1 plan         # Planning mode (OPTIONAL)
  .\scripts\ralph-loop.ps1 --rlm-context .\rlm\context.txt
  .\scripts\ralph-loop.ps1 --rlm .\rlm\context.txt

Modes:
  build (default)  Pick incomplete spec and implement
  plan             Create IMPLEMENTATION_PLAN.md (OPTIONAL)

Work Source:
  Agent reads specs/*.md and picks the highest priority incomplete spec.

RLM Mode (optional):
  --rlm-context <file>  Treat a large context file as external environment.
  --rlm [file]          Shortcut for --rlm-context (defaults to rlm/context.txt)
"@ | Write-Host
}

$claudeCmd = if ($env:CLAUDE_CMD) { $env:CLAUDE_CMD } else { "claude" }

$missingCli = @"
Error: Claude CLI not found

Install one of these AI coding CLIs:

1. Claude Code CLI (recommended for this script):
   https://claude.ai/code

2. GitHub Copilot CLI:
   npm install -g @github/copilot-cli
   Run with: ./scripts/ralph-loop-copilot.sh or .\scripts\ralph-loop-copilot.ps1

3. Google Gemini CLI:
   npm install -g @google/gemini-cli
   Run with: ./scripts/ralph-loop-gemini.sh or .\scripts\ralph-loop-gemini.ps1

4. OpenAI Codex CLI:
   npm install -g @openai/codex
   Run with: ./scripts/ralph-loop-codex.sh or .\scripts\ralph-loop-codex.ps1
"@

$config = @{
    AgentName = "Claude"
    DisplayName = "              RALPH LOOP (Claude Code) STARTING              "
    SessionPrefix = "ralph"
    Command = $claudeCmd
    PromptMode = "Pipe"
    BaseFlags = @("-p")
    SupportsYolo = $true
    YoloFlag = "--dangerously-skip-permissions"
    HelpCallback = { Show-ClaudeHelp }
    MissingCliMessage = $missingCli
}

Invoke-RalphLoop -Config $config -Args $args
