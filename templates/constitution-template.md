# [PROJECT_NAME] Constitution

> [PROJECT_DESCRIPTION]

## Version
1.0.0

## Core Principles

### I. [PRINCIPLE_1_NAME]
<!-- Example: API-First Architecture, Component-Based Design, etc. -->
[Describe your first core principle]

### II. [PRINCIPLE_2_NAME]
[Describe your second core principle]

### III. Simplicity & YAGNI
Start simple. Avoid over-engineering. Build exactly what's needed, nothing more.
No premature abstractions. No "just in case" features.

### IV. Autonomous Agent Development (YOLO Mode)
AI coding agents MUST work as autonomously as possible:

- Make decisions without asking for approval on implementation details
- **Commit and push autonomously** - don't wait for user to commit
- Deploy without user intervention
- Monitor deployments and fix issues independently
- Only ask the user when genuinely stuck

This is enabled by extensive testing:
- Unit tests, integration tests, browser automation
- Smoke tests after each deploy
- Production testing

### V. Quality Standards
<!-- Customize: Add your quality requirements -->
[Describe your quality expectations - design system, code standards, etc.]

## Technical Stack

| Layer | Technology | Notes |
|-------|------------|-------|
| Framework | [YOUR_FRAMEWORK] | e.g., Next.js, FastAPI, etc. |
| Language | [YOUR_LANGUAGE] | e.g., TypeScript, Python |
| Styling | [YOUR_STYLING] | e.g., Tailwind CSS |
| Testing | [YOUR_TESTING] | e.g., Vitest + Playwright |
| Deployment | [YOUR_DEPLOYMENT] | e.g., Render, Vercel |

## API Integration (if applicable)

<!-- Customize: Add your API endpoints -->
- Main API: [YOUR_API_URL]
- Documentation: [YOUR_API_DOCS]

## Development Workflow

This project follows the **Ralph Wiggum + SpecKit** methodology:

1. **Constitution** -> Define principles (this file)
2. **Spec** -> Create feature specifications with Completion Signals - `/speckit.specify`
3. **Implement** -> Execute via Ralph Wiggum iterative loops - `/speckit.implement`

### Completion Signal

Every spec includes a Completion Signal section with:
- Implementation checklist
- Testing requirements
- Completion promise: `<promise>DONE</promise>`

Agents iterate until all checks pass.

## Governance

- **Amendments**: Update this file, increment version, note changes
- **Compliance**: Follow principles in spirit, not just letter
- **Exceptions**: Document and justify in specs when deviating

**Version**: 1.0.0 | **Created**: [DATE]
