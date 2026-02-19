# Ralph Wiggum PowerShell Script Review & Improvements

I have completed a comprehensive review and update of the Ralph Wiggum PowerShell scripts to ensure they are production-ready, cross-platform, and robust.

## Key Improvements Implemented

1.  **Fixed Windows Command Line Limits:**
    -   **Issue:** Passing large prompts as command-line arguments (e.g., `-p "content"`) often fails on Windows due to the ~8191 character limit.
    -   **Fix:** Updated `ralph-loop-gemini.ps1`, `ralph-loop-copilot.ps1`, and `ralph-loop-codex.ps1` to pipe the prompt content via Standard Input (stdin). This is the standard, reliable method for passing large data to CLI tools.

2.  **Centralized Initialization Logic:**
    -   **Action:** Created a new shared library: `scripts/lib/common.ps1`.
    -   **Benefit:** This library now handles:
        -   Directory creation (`logs/`, `rlm/`).
        -   Prompt file generation (`PROMPT_build.md`, `PROMPT_plan.md`).
        -   RLM (Recursive Language Model) context setup.
        -   YOLO mode detection from the Constitution.
    -   **Result:** All loop scripts (Claude, Gemini, Copilot, Codex) now share the exact same robust initialization logic, reducing code duplication and preventing "missing file" errors when switching models.

3.  **Documentation Updates:**
    -   **Action:** Updated `SKILL.md` to include specific usage instructions for **Google Gemini** and **GitHub Copilot** scripts, which were previously undocumented.

## Files Created/Updated

-   `scripts/lib/common.ps1` (New shared library)
-   `scripts/ralph-loop.ps1` (Updated to use common lib)
-   `scripts/ralph-loop-gemini.ps1` (Updated to use common lib + pipe input)
-   `scripts/ralph-loop-copilot.ps1` (Updated to use common lib + pipe input)
-   `scripts/ralph-loop-codex.ps1` (Updated to use common lib)
-   `SKILL.md` (Updated documentation)

## How to Use

You can now run any of the loop scripts with confidence. They will automatically set up the necessary environment (prompts, logs) on the first run.

**Gemini:**
```powershell
.\scriptsalph-loop-gemini.ps1
```

**GitHub Copilot:**
```powershell
.\scriptsalph-loop-copilot.ps1
```

**Claude Code:**
```powershell
.\scriptsalph-loop.ps1
```
