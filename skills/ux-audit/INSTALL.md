# UX Audit Skill — Installation Guide

## Prerequisites

- **Claude Code CLI** (`claude`) — [claude.ai/code](https://claude.ai/code)
- **Figma MCP server** — configured in your Claude MCP settings. Used for `mcp__figma__*` tools throughout the audit.
- **Optics MCP server** (optional, recommended) — `mcp__optics__*` tools enable automatic token mapping and contrast checking. Without it the skill falls back to grep-based analysis.
- **Node.js 18+** — required for token generation scripts

---

## Install from rolemodel-design-skills

### 1. Clone the repo (if you haven't already)

```bash
git clone git@github.com:RoleModel/rolemodel-design-skills.git /path/to/rolemodel-design-skills
```

### 2. Symlink the skill into Claude Code

```bash
ln -s /path/to/rolemodel-design-skills/skills/ux-audit ~/.claude/skills/ux-audit
```

Verify it's available — restart Claude Code and check that `/ux-audit` appears in skill completions.

### 3. Configure MCP servers

In your `~/.claude/mcp.json` (or equivalent), ensure you have the Figma and Optics servers configured:

```json
{
  "mcpServers": {
    "figma": {
      "command": "npx",
      "args": ["-y", "@figma/mcp-server"],
      "env": { "FIGMA_ACCESS_TOKEN": "YOUR_TOKEN" }
    },
    "optics": {
      "command": "npx",
      "args": ["-y", "@rolemodel/optics-mcp"]
    }
  }
}
```

---

## Per-project Setup

### 1. Create `.ux-audit.json` in the project root

Run `/ux-audit` and Claude will prompt you for answers and create the file, or create it manually:

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

**Key fields:**
- `audience` — `"client"` or `"internal"`. This changes everything: tone, report structure, finding language.
- `brand.caseStudyUrl` — if set, Claude fetches the case study to ground the "Then" section in real context and pull the hero image.
- `figma.fileKey` — leave `null` to create a new file, or paste an existing key from a Figma URL.

### 2. Run the audit

```bash
# Full audit (all 5 phases)
/ux-audit

# Individual phases
/ux-audit scan
/ux-audit tokens
/ux-audit accessibility
/ux-audit report
/ux-audit figma
```

### 3. Push to Figma

After Phase 4 generates the HTML report:

```bash
/ux-audit figma
```

This uses `mcp__figma__generate_figma_design` to push the report. Claude will start a local HTTP server, open the page in your browser, and poll for completion.

---

## Non-Optics Projects

The skill works on any web project. When `designSystem.name` is not `"optics"`, token mapping falls back to grep-based analysis against whatever CSS/token files it finds in `node_modules` or the project. Set `designSystem.name` to match the system in use (e.g. `"tailwind"`, `"bootstrap"`, `"custom"`).

---

## Updating the Skill

```bash
cd /path/to/rolemodel-design-skills
git pull
```

The symlink means your Claude Code installation picks up changes immediately — no reinstall needed.
