#!/usr/bin/env bash
#
# run-audit-agent.sh
#
# Runs a UX audit autonomously on a project using the Claude Code CLI.
# Claude will run all 5 phases and write the report without interactive input.
#
# Usage:
#   ./run-audit-agent.sh [project-dir] [--client|--internal] [phase]
#
# Examples:
#   ./run-audit-agent.sh ~/Development/my-app --client
#   ./run-audit-agent.sh ~/Development/my-app --internal scan
#   ./run-audit-agent.sh . --client report
#
# Prerequisites:
#   - Claude Code CLI installed: https://claude.ai/code
#   - .ux-audit.json present in project-dir (or Claude will prompt to create it)
#   - Figma and Optics MCP servers configured in ~/.claude/mcp.json
#

set -euo pipefail

PROJECT_DIR="${1:-.}"
MODE="${2:---client}"
PHASE="${3:-}"

# Resolve absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: directory not found: $PROJECT_DIR" >&2
  exit 1
fi

echo "Running UX audit on: $PROJECT_DIR"
echo "Mode: $MODE"
[ -n "$PHASE" ] && echo "Phase: $PHASE" || echo "Phase: full (all 5)"
echo ""

# Build the command
COMMAND="/ux-audit $MODE"
[ -n "$PHASE" ] && COMMAND="/ux-audit $PHASE $MODE"

# Run Claude Code in non-interactive mode
# --print: output to stdout, no interactive UI
# --dangerously-skip-permissions: allow file writes without prompting (audit is read-heavy, report write is safe)
claude \
  --print \
  --dangerously-skip-permissions \
  --cwd "$PROJECT_DIR" \
  "$COMMAND"
