# Installing Ralph Wiggum

## The Easy Way (Recommended)

Just tell your AI assistant:

> "Set up Ralph Wiggum in this project using https://github.com/fstandhartinger/ralph-wiggum"

The AI will read the AGENTS.md file and install everything automatically.

## Manual Installation

If you prefer to install manually:

1. Clone the templates:
   ```bash
   git clone https://github.com/fstandhartinger/ralph-wiggum.git /tmp/ralph-wiggum
   cp -r /tmp/ralph-wiggum/templates ./templates
   cp -r /tmp/ralph-wiggum/scripts ./scripts
   cp -r /tmp/ralph-wiggum/.cursor ./.cursor
   ```

2. Create your constitution:
   ```bash
   mkdir -p .specify/memory
   cp /tmp/ralph-wiggum/templates/constitution-template.md .specify/memory/constitution.md
   ```

3. Edit the constitution with your project-specific principles.

4. You're ready! Use `/speckit.specify` to create specs.
