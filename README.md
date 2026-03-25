![UI/UX Audit Skill](https://ik.imagekit.io/dtunrco/Ox_TPIFD9IbLFwUwSkYoe4BJ6CGJWo-ba19G1ZGXNwI.png)

# UX Audit Skill

Run structured UX/UI audits on web projects with Claude Code. Scans for hardcoded CSS, accessibility issues, and design token gaps. Outputs to reveal.js slide decks, Figma canvas, or scrollable HTML.

## Quick Start

```bash
git clone git@github.com:RoleModel/rolemodel-design-audit.git
cd rolemodel-design-audit
./scripts/setup.sh
```

The setup script checks everything, installs what it can, and symlinks the skill into Claude Code. When it finishes, open Claude Code in any project and type `/ux-audit`.

## What the Setup Script Does

1. **Checks core dependencies** — Claude Code CLI, Node.js 18+
2. **Checks optional tools** — ripgrep (for CSS scanning), GitHub CLI (for project search)
3. **Symlinks the skill** into `~/.claude/skills/ux-audit`
4. **Checks Figma MCP** — detects the Figma plugin or manual MCP config
5. **Sets script permissions** — makes all shell scripts executable

If anything is missing, the script tells you exactly what to install and how.

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

## Non-Optics Projects

The skill works on any web project. Set `designSystem.name` to match your system (`"tailwind"`, `"bootstrap"`, `"custom"`). Token mapping falls back to grep-based analysis when Optics MCP tools aren't available.

## Updating

```bash
cd rolemodel-design-audit
git pull
```

The symlink means Claude Code picks up changes immediately.
