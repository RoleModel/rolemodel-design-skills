#!/usr/bin/env bash
#
# run-audit-agent.sh
#
# Runs a UX audit autonomously on a project using the Claude Code CLI.
# Claude will run all phases and write the report without interactive input.
#
# Usage:
#   ./run-audit-agent.sh                                    # Interactive mode
#   ./run-audit-agent.sh [project-dir] [mode] [format] [phase] [figma-key]  # Headless mode
#
# Examples:
#   ./run-audit-agent.sh
#   ./run-audit-agent.sh ~/Development/my-app --client reveal full
#   ./run-audit-agent.sh ~/Development/my-app --internal html report
#   ./run-audit-agent.sh ~/Development/my-app --client figma full abc123XYZ
#
# Prerequisites:
#   - Claude Code CLI installed: https://claude.ai/code
#   - .ux-audit.json present in project-dir (or Claude will prompt to create it)
#   - Figma and Optics MCP servers configured in ~/.claude/mcp.json
#

set -euo pipefail

# --- Colors ---
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

prompt() {
  local message="$1"
  local default="$2"
  local varname="$3"
  printf "${BLUE}${BOLD}  %s${RESET} ${GREEN}[%s]${RESET}${BLUE}: ${RESET}" "$message" "$default"
  read -r input
  eval "$varname=\"${input:-$default}\""
}

prompt_choice() {
  local message="$1"
  local options="$2"
  local default="$3"
  local varname="$4"
  printf "${BLUE}${BOLD}  %s${RESET} ${DIM}(%s)${RESET} ${GREEN}[%s]${RESET}${BLUE}: ${RESET}" "$message" "$options" "$default"
  read -r input
  eval "$varname=\"${input:-$default}\""
}

# --- Header ---
echo ""
printf "${CYAN}${BOLD}  ╔══════════════════════════════════════════╗${RESET}\n"
printf "${CYAN}${BOLD}  ║         UX Audit Agent Runner            ║${RESET}\n"
printf "${CYAN}${BOLD}  ║   Automated design review with Claude    ║${RESET}\n"
printf "${CYAN}${BOLD}  ╚══════════════════════════════════════════╝${RESET}\n"
echo ""

# --- Interactive or headless ---
if [ $# -eq 0 ]; then
  # Interactive mode
  printf "${DIM}  Answer the prompts below. Press Enter to accept defaults.${RESET}\n"
  echo ""

  prompt "Project directory" "$(pwd)" PROJECT_DIR
  prompt_choice "Audience mode" "client, internal" "client" MODE_RAW
  prompt_choice "Output format" "html, reveal, figma" "reveal" FORMAT
  prompt_choice "Phase" "full, scan, tokens, accessibility, report, figma, publish" "full" PHASE

  FIGMA_KEY=""
  if [ "$FORMAT" = "figma" ]; then
    echo ""
    printf "${YELLOW}  Figma format selected. A Figma file key is needed.${RESET}\n"
    prompt "Figma file key (or 'create new')" "create new" FIGMA_KEY
  fi

  # Normalize mode flag
  MODE="--${MODE_RAW}"
else
  # Headless mode - parse positional args
  PROJECT_DIR="${1:-.}"
  MODE="${2:---client}"
  FORMAT="${3:-reveal}"
  PHASE="${4:-full}"
  FIGMA_KEY="${5:-}"
fi

# --- Resolve absolute path ---
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [ ! -d "$PROJECT_DIR" ]; then
  printf "${YELLOW}  Error: directory not found: %s${RESET}\n" "$PROJECT_DIR" >&2
  exit 1
fi

# --- Summary ---
echo ""
printf "${CYAN}${BOLD}  ── Configuration ──────────────────────────${RESET}\n"
printf "${BOLD}  Project:  ${RESET}%s\n" "$PROJECT_DIR"
printf "${BOLD}  Mode:     ${RESET}%s\n" "$MODE"
printf "${BOLD}  Format:   ${RESET}%s\n" "$FORMAT"
if [ "$PHASE" = "full" ]; then
  printf "${BOLD}  Phase:    ${RESET}full (all phases)\n"
else
  printf "${BOLD}  Phase:    ${RESET}%s\n" "$PHASE"
fi
if [ -n "$FIGMA_KEY" ]; then
  printf "${BOLD}  Figma:    ${RESET}%s\n" "$FIGMA_KEY"
fi
printf "${CYAN}  ─────────────────────────────────────────────${RESET}\n"
echo ""

# --- Build the command ---
COMMAND="/ux-audit"
if [ "$PHASE" != "full" ]; then
  COMMAND="/ux-audit $PHASE"
fi
COMMAND="$COMMAND $MODE"

# Append format if not the default html
if [ "$FORMAT" != "html" ]; then
  COMMAND="$COMMAND --format $FORMAT"
fi

# Append figma key if provided
if [ -n "$FIGMA_KEY" ] && [ "$FIGMA_KEY" != "create new" ]; then
  COMMAND="$COMMAND --figma-key $FIGMA_KEY"
fi

printf "${DIM}  Running: claude --print --dangerously-skip-permissions --cwd \"%s\" \"%s\"${RESET}\n" "$PROJECT_DIR" "$COMMAND"
echo ""

# --- Run Claude Code in non-interactive mode ---
# --print: output to stdout, no interactive UI
# --dangerously-skip-permissions: allow file writes without prompting (audit is read-heavy, report write is safe)
claude \
  --print \
  --dangerously-skip-permissions \
  --cwd "$PROJECT_DIR" \
  "$COMMAND"
