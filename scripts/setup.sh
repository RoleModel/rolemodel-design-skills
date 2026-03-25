#!/usr/bin/env bash
#
# setup.sh — One-command setup for the UX Audit skill.
#
# Checks all prerequisites, installs what it can, symlinks the skill
# into Claude Code, and verifies MCP server configuration.
#
# Usage:
#   ./scripts/setup.sh
#
# Run from the repo root (rolemodel-design-audit/).

set -euo pipefail

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

pass()  { printf "${GREEN}  ✓ %s${RESET}\n" "$1"; }
warn()  { printf "${YELLOW}  ⚠ %s${RESET}\n" "$1"; }
fail()  { printf "${RED}  ✗ %s${RESET}\n" "$1"; }
info()  { printf "${DIM}    %s${RESET}\n" "$1"; }
header(){ printf "\n${CYAN}${BOLD}  %s${RESET}\n" "$1"; }

ERRORS=0
WARNINGS=0

# --- Resolve repo root ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_DIR="$REPO_ROOT/skills/ux-audit"

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  fail "Cannot find skills/ux-audit/SKILL.md — run this script from the repo root."
  exit 1
fi

# --- Header ---
echo ""
printf "${CYAN}${BOLD}  ╔══════════════════════════════════════════╗${RESET}\n"
printf "${CYAN}${BOLD}  ║         UX Audit Skill Setup             ║${RESET}\n"
printf "${CYAN}${BOLD}  ╚══════════════════════════════════════════╝${RESET}\n"

# ─────────────────────────────────────────────────────────────────────
header "1. Core Dependencies"
# ─────────────────────────────────────────────────────────────────────

# Claude Code CLI
if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
  pass "Claude Code CLI ($CLAUDE_VERSION)"
else
  fail "Claude Code CLI not found"
  info "Install: https://claude.ai/code"
  ERRORS=$((ERRORS + 1))
fi

# Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node --version 2>/dev/null)
  NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 18 ] 2>/dev/null; then
    pass "Node.js $NODE_VERSION"
  else
    warn "Node.js $NODE_VERSION (18+ recommended)"
    info "Token generation scripts may not work with older versions."
    WARNINGS=$((WARNINGS + 1))
  fi
else
  fail "Node.js not found"
  info "Install: brew install node  (or https://nodejs.org)"
  ERRORS=$((ERRORS + 1))
fi

# ─────────────────────────────────────────────────────────────────────
header "2. Optional Tools"
# ─────────────────────────────────────────────────────────────────────

# ripgrep (used by scan-hardcoded-values.sh)
if command -v rg &>/dev/null; then
  pass "ripgrep (rg) — used by scan-hardcoded-values.sh"
else
  warn "ripgrep not found — scan-hardcoded-values.sh won't work"
  info "Install: brew install ripgrep"
  WARNINGS=$((WARNINGS + 1))
fi

# GitHub CLI (used by run-audit-agent.sh for project search)
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    pass "GitHub CLI (gh) — authenticated"
  else
    warn "GitHub CLI (gh) installed but not authenticated"
    info "Run: gh auth login"
    WARNINGS=$((WARNINGS + 1))
  fi
else
  warn "GitHub CLI not found — project search from GitHub won't work"
  info "Install: brew install gh"
  WARNINGS=$((WARNINGS + 1))
fi

# ─────────────────────────────────────────────────────────────────────
header "3. Skill Installation"
# ─────────────────────────────────────────────────────────────────────

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
SKILL_LINK="$CLAUDE_SKILLS_DIR/ux-audit"

if [ -L "$SKILL_LINK" ]; then
  LINK_TARGET=$(readlink "$SKILL_LINK" 2>/dev/null || readlink -f "$SKILL_LINK" 2>/dev/null)
  if [ "$LINK_TARGET" = "$SKILL_DIR" ]; then
    pass "Skill symlinked → $SKILL_LINK"
  else
    warn "Skill symlink exists but points to: $LINK_TARGET"
    info "Expected: $SKILL_DIR"
    printf "${BLUE}${BOLD}  Update symlink? ${RESET}${GREEN}[yes]${RESET}${BLUE}: ${RESET}"
    read -r CONFIRM
    CONFIRM="${CONFIRM:-yes}"
    if [ "$CONFIRM" = "yes" ] || [ "$CONFIRM" = "y" ]; then
      rm "$SKILL_LINK"
      ln -s "$SKILL_DIR" "$SKILL_LINK"
      pass "Symlink updated"
    fi
  fi
elif [ -d "$SKILL_LINK" ]; then
  warn "Skill directory exists (not a symlink): $SKILL_LINK"
  info "Remove it and re-run setup to use the repo version."
  WARNINGS=$((WARNINGS + 1))
else
  mkdir -p "$CLAUDE_SKILLS_DIR"
  ln -s "$SKILL_DIR" "$SKILL_LINK"
  pass "Skill symlinked → $SKILL_LINK"
fi

# ─────────────────────────────────────────────────────────────────────
header "4. Figma MCP Server"
# ─────────────────────────────────────────────────────────────────────

# Check if Figma plugin is enabled in Claude Code
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
FIGMA_CONFIGURED=false

if [ -f "$CLAUDE_SETTINGS" ]; then
  # Check for Figma plugin in enabledPlugins
  if grep -q 'figma.*claude-plugins' "$CLAUDE_SETTINGS" 2>/dev/null; then
    pass "Figma plugin enabled in Claude Code"
    FIGMA_CONFIGURED=true
  fi
fi

# Also check mcp.json for manual Figma server config
CLAUDE_MCP="$HOME/.claude/mcp.json"
if [ -f "$CLAUDE_MCP" ]; then
  if grep -q '"figma"' "$CLAUDE_MCP" 2>/dev/null; then
    pass "Figma MCP server found in mcp.json"
    FIGMA_CONFIGURED=true
  fi
fi

if ! $FIGMA_CONFIGURED; then
  warn "Figma MCP not detected"
  info "The Figma plugin provides screenshot, canvas write, and design inspection tools."
  info "Without it, the skill still works but skips Figma-dependent features."
  echo ""
  info "To install the official Figma plugin:"
  printf "${CYAN}    claude plugin add figma${RESET}\n"
  echo ""
  info "Or add manually to ~/.claude/mcp.json:"
  printf "${DIM}    {\"mcpServers\": {\"figma\": {\"command\": \"npx\", \"args\": [\"-y\", \"@figma/mcp-server\"], \"env\": {\"FIGMA_ACCESS_TOKEN\": \"YOUR_TOKEN\"}}}}${RESET}\n"
  WARNINGS=$((WARNINGS + 1))
fi

# ─────────────────────────────────────────────────────────────────────
header "5. Script Permissions"
# ─────────────────────────────────────────────────────────────────────

SCRIPTS=(
  "$SKILL_DIR/scripts/scan-hardcoded-values.sh"
  "$SKILL_DIR/scripts/publish-report.sh"
  "$SKILL_DIR/scripts/run-audit-agent.sh"
  "$REPO_ROOT/scripts/setup.sh"
)

MADE_EXECUTABLE=0
for script in "${SCRIPTS[@]}"; do
  if [ -f "$script" ] && [ ! -x "$script" ]; then
    chmod +x "$script"
    MADE_EXECUTABLE=$((MADE_EXECUTABLE + 1))
  fi
done

if [ $MADE_EXECUTABLE -gt 0 ]; then
  pass "Made $MADE_EXECUTABLE scripts executable"
else
  pass "All scripts already executable"
fi

# ─────────────────────────────────────────────────────────────────────
header "Summary"
# ─────────────────────────────────────────────────────────────────────

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  printf "${GREEN}${BOLD}  All clear! The skill is ready to use.${RESET}\n"
elif [ $ERRORS -eq 0 ]; then
  printf "${YELLOW}${BOLD}  Ready with %d warning(s). The skill will work — some optional features may be limited.${RESET}\n" "$WARNINGS"
else
  printf "${RED}${BOLD}  %d error(s) and %d warning(s). Fix the errors above before using the skill.${RESET}\n" "$ERRORS" "$WARNINGS"
fi

echo ""
printf "${DIM}  To run an audit, open Claude Code in a project directory and type:${RESET}\n"
printf "${CYAN}    /ux-audit${RESET}\n"
echo ""
