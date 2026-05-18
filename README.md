![UI/UX Audit Skill](https://ik.imagekit.io/dtunrco/Ox_TPIFD9IbLFwUwSkYoe4BJ6CGJWo-ba19G1ZGXNwI.png)

# UX Audit Skill

Run structured UX/UI audits on web projects with Claude Code. Scans for hardcoded CSS, accessibility issues, and design token gaps. Outputs to reveal.js slide decks, Figma canvas, or scrollable HTML.

## Installation

### Option 1: Setup Script (Recommended — Claude Code)

```bash
git clone git@github.com:RoleModel/rolemodel-design-audit.git
cd rolemodel-design-audit
./scripts/setup.sh
```

The setup script checks prerequisites, symlinks the skill into `~/.claude/skills/ux-audit`, and tells you exactly what to install if anything is missing. After it finishes, open Claude Code in any project and type `/ux-audit`.

### Option 2: Manual Symlink

```bash
ln -s "$(pwd)/skills/ux-audit" ~/.claude/skills/ux-audit
```

Or for opencode, place a symlink (or copy) into `~/.config/opencode/skills/ux-audit/`.

## What the Setup Script Does

1. **Checks core dependencies** — Claude Code CLI, Node.js 18+
2. **Checks optional tools** — ripgrep (for CSS scanning), GitHub CLI (for project search)
3. **Symlinks the skill** into `~/.claude/skills/ux-audit`
4. **Checks Figma MCP** — detects the Figma plugin or manual MCP config
5. **Sets script permissions** — makes all shell scripts executable

If anything is missing, the script tells you exactly what to install and how.

## Source of Truth and Repo Layout

This repository is the maintained source of truth for `/ux-audit`.

- **Claude Code** uses a symlink created by `./scripts/setup.sh`, so pulling this repo updates that install immediately.
- **Other AI CLIs** (Codex, Cursor, etc.) can use a copy or symlink. Refresh from this repo when the workflow is intentionally promoted.
- **Project examples and demos** live in the sibling `rolemodel-ux-audit-projects` repo so this skill repo stays light to clone.

```text
skills/ux-audit/
  SKILL.md                 # Workflow contract — the /ux-audit command
  AGENT.md                 # Headless/autonomous agent configuration
  RETROSPECTIVE.md         # Development lessons and design decisions
  scripts/
    run-audit-agent.sh     # Interactive or headless audit runner
    publish-report.sh      # Vercel/Netlify/Surge publisher
    scan-hardcoded-values.sh  # Grep wrapper for Phase 1
    generate-figma-variables.mjs  # Optics → DTCG token JSON
    generate-all-tokens.mjs       # Full token generation pipeline
  references/
    html-template/         # Scrollable HTML report templates (internal, client, magazine)
    revealjs-template/     # Reveal.js slide deck bundle + audit-kit web components
    figma-workflow.md      # Figma MCP canvas-write workflow
    tone-guide.md          # Language rules for internal vs client mode
    team-guide.md          # Client audit philosophy (Then/Now/Next)
    severity-model.md      # Critical/High/Medium/Pattern classification
    laws-of-ux.md          # 21 Laws of UX reference
    audit-checklist.md     # Scan patterns for hardcoded values
    dtcg-format.md         # DTCG token JSON specification
    demo-recording-guide.md  # Playwright + ffmpeg demo recording workflow
```

For the farming workflow, treat the outputs as a contract:

- `reveal` → copy the full `revealjs-template/` bundle and compose slides with the provided audit-kit components
- `html` → use `html-template/` plus its companion CSS
- `figma` → duplicate the Figma template and populate it through the documented Figma flow
- `publish` → package the generated report and assets, then deploy through the publish script

Concrete audit outputs and heavier demos belong in the separate `rolemodel-ux-audit-projects` repo. Keep static audit reports as normal folders there; use git submodules for larger demo apps so people can opt into those checkouts instead of downloading every project by default.

## Updating

```bash
cd rolemodel-design-audit
git pull
```

The symlink means Claude Code picks up changes immediately. For copied installs, re-run the copy or update the symlink target.

## Per-project Setup

Run `/ux-audit` in a project directory. Claude will ask a few questions and create `.ux-audit.json` for you:

- **Audience** — `"client"` (polished, narrative) or `"internal"` (direct, technical)
- **Brand colors** — primary hue/saturation from the project
- **Design system** — defaults to `@rolemodel/optics`, works with any system
- **Figma file key** — for canvas output (optional)
- **Case study URL** — for cover images and narrative context (optional)

Or create `.ux-audit.json` manually:

```json
{
  "audience": "client",
  "designSystem": {
    "name": "optics",
    "package": "@rolemodel/optics",
    "tokenPrefix": "--op-"
  },
  "brand": {
    "name": "ProjectName",
    "primaryHue": 46,
    "primarySaturation": 97,
    "primaryLightness": 49,
    "neutralHue": 226,
    "neutralSaturation": 5,
    "fontFamily": "DM Sans",
    "caseStudyUrl": "https://rolemodelsoftware.com/case-studies/your-project"
  },
  "figma": {
    "fileKey": null,
    "outputMode": "newFile"
  },
  "outputDir": "dev-tools/ux-audit-output",
  "appUrl": "http://localhost:3000"
}
```

## Usage

```bash
# Full audit — scans, maps tokens, audits, walks findings interactively
/ux-audit

# Generate client report (after design work is done)
/ux-audit report

# Individual phases
/ux-audit scan        # Tech stack + codebase scan
/ux-audit tokens      # Design token mapping
/ux-audit audit       # Heuristic audit (10 sections)
/ux-audit review      # Interactive finding review
/ux-audit figma       # Figma deliverables + token JSON
/ux-audit publish     # Deploy to Vercel/Netlify/Surge
```

### Shell Scripts (Automation)

```bash
# Interactive — prompts for project, audience, format
./skills/ux-audit/scripts/run-audit-agent.sh

# Headless — for CI or automation
./skills/ux-audit/scripts/run-audit-agent.sh ~/Development/my-app --client reveal

# Publish report to a URL
./skills/ux-audit/scripts/publish-report.sh
```

## Publishing with Vercel

The default publish path is Vercel. After a report is generated, run:

```bash
./skills/ux-audit/scripts/publish-report.sh
```

The script reads `.ux-audit.json`, packages the report and its local assets, links the temporary deploy directory to the configured Vercel project name, and deploys to production. On first use, authenticate once with `npx vercel login`; later publishes can run headlessly. Set `publish.projectName` in `.ux-audit.json` when you want a stable client-facing slug such as `rapidair-assessment`.

## Non-Optics Projects

The skill works on any web project. Set `designSystem.name` to match your system (`"tailwind"`, `"bootstrap"`, `"custom"`). Token mapping falls back to grep-based analysis when Optics MCP tools aren't available.
