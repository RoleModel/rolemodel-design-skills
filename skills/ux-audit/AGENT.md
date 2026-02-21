# UX Audit Agent

An autonomous agent configuration for running `/ux-audit` without interactive input. Useful for running audits on new projects, integrating into project onboarding, or re-running audits after significant changes.

---

## What the Agent Does

The agent runs in a project directory and executes the full `/ux-audit` skill workflow:

1. Detects tech stack and scans for hardcoded CSS values
2. Maps values to the target design system (Optics MCP if available)
3. Runs static accessibility analysis
4. Generates an HTML audit report from the appropriate template
5. Optionally pushes deliverables to Figma and generates DTCG token JSON

At the end it reports the output file path and any Figma URLs.

---

## Shell Agent

The simplest form. Uses the Claude Code CLI in non-interactive mode.

```bash
# scripts/run-audit-agent.sh — already included in this skill
./scripts/run-audit-agent.sh [project-dir] [--client|--internal] [phase]

# Examples
./scripts/run-audit-agent.sh ~/Development/my-app --client
./scripts/run-audit-agent.sh ~/Development/my-app --internal scan
./scripts/run-audit-agent.sh . --client report
```

See [scripts/run-audit-agent.sh](scripts/run-audit-agent.sh) for the implementation.

---

## Agent Configuration

Configure the agent using standard environment variables and the tool list below. The agent is model- and provider-agnostic — use whichever LLM and API client your project uses.

### System prompt

```
You are running a UX audit on a web project. Follow the /ux-audit skill exactly.
Complete all phases without asking for confirmation. Write findings based only on
what you observe in the code — never fabricate. When done, report the output file
path and any Figma URLs.
```

### User message

```
/ux-audit --client
```

Or for a specific phase:

```
/ux-audit scan --internal
```

### Required tools

The audit is primarily read-only. Provide these tools to the agent:

```
# Codebase access (read-only)
Read, Glob, Grep

# Report output (write to outputDir only)
Write

# Token generation + HTTP server for Figma export
Bash(node:*), Bash(python3:*), Bash(mkdir:*), Bash(lsof:*), Bash(open:*)

# Design system token lookup + contrast checking
mcp__optics__search_tokens
mcp__optics__suggest_token_migration
mcp__optics__check_contrast
mcp__optics__list_components
mcp__optics__get_component_tokens
mcp__optics__get_token
mcp__optics__validate_token_usage

# Figma — design inspection + report export
mcp__figma__get_design_context
mcp__figma__get_screenshot
mcp__figma__get_metadata
mcp__figma__generate_figma_design
mcp__figma__get_variable_defs

# Optional — for fetching case study URLs
WebFetch, WebSearch
```

### Settings

```
max_turns: 80      # Full audit with all phases needs room to work
cwd: <project-dir> # Set to the project root before invoking
```

---

## Recommended Permissions

The only writes the agent makes:
- `.ux-audit.json` — config, created on first run if missing
- `{outputDir}/ux-audit-report.html` — the report
- `{outputDir}/light.tokens.json` + `dark.tokens.json` — DTCG token files (Phase 5 only)

For fully autonomous runs, scope `Write` to `{outputDir}/*` and `.ux-audit.json` only.

---

## Autonomous vs. Interactive

| Mode | When to use |
|------|-------------|
| **Interactive** (`/ux-audit` in Claude Code) | First run on a new project, reviewing findings at each phase, iterating on report design |
| **Autonomous** (shell script or SDK) | Re-running after code changes, CI integration, onboarding a new project to a standard audit baseline |

For the first run on any project, interactive mode is preferred — the agent will ask about audience, design system, and Figma preferences before creating `.ux-audit.json`. After that config exists, autonomous runs work cleanly.

---

## CI Integration Example

```yaml
# .github/workflows/ux-audit.yml
name: UX Audit
on:
  workflow_dispatch:
    inputs:
      audience:
        description: "Audience mode"
        default: "internal"
        type: choice
        options: [internal, client]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run UX Audit
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          npx @anthropic-ai/claude-code \
            --print \
            --dangerously-skip-permissions \
            "/ux-audit --${{ inputs.audience }}"
      - uses: actions/upload-artifact@v4
        with:
          name: ux-audit-report
          path: dev-tools/ux-audit-output/
```
