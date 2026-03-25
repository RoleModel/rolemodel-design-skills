#!/usr/bin/env bash
#
# publish-report.sh
#
# Deploys a UX audit report to a public URL as a static site.
#
# Usage:
#   ./publish-report.sh                                          # Interactive mode
#   ./publish-report.sh [output-dir] [--provider vercel|netlify|surge] [--name project-name]
#
# Examples:
#   ./publish-report.sh
#   ./publish-report.sh dev-tools/ux-audit-output
#   ./publish-report.sh dev-tools/ux-audit-output --provider netlify
#   ./publish-report.sh dev-tools/ux-audit-output --provider vercel --name my-app-ux-audit
#
# Prerequisites:
#   - Node.js installed (for npx)
#   - For Vercel: authenticated via `npx vercel login` or VERCEL_TOKEN env var
#   - For Netlify: authenticated via `npx netlify-cli login` or NETLIFY_AUTH_TOKEN env var
#   - For Surge: authenticated via `npx surge login`
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
printf "${CYAN}${BOLD}  ║       UX Audit Report Publisher          ║${RESET}\n"
printf "${CYAN}${BOLD}  ║   Deploy your report to a public URL     ║${RESET}\n"
printf "${CYAN}${BOLD}  ╚══════════════════════════════════════════╝${RESET}\n"
echo ""

# --- Auto-detect defaults from .ux-audit.json ---
AUTO_OUTPUT_DIR="dev-tools/ux-audit-output"
AUTO_PROJECT_NAME="assessment"

if [ -f .ux-audit.json ]; then
  DETECTED_DIR=$(python3 -c "import json; print(json.load(open('.ux-audit.json')).get('outputDir', ''))" 2>/dev/null || echo "")
  if [ -n "$DETECTED_DIR" ]; then
    AUTO_OUTPUT_DIR="$DETECTED_DIR"
  fi

  DETECTED_BRAND=$(python3 -c "import json; print(json.load(open('.ux-audit.json')).get('brand', {}).get('name', ''))" 2>/dev/null || echo "")
  DETECTED_PUBLISH_NAME=$(python3 -c "import json; print(json.load(open('.ux-audit.json')).get('publish', {}).get('projectName', ''))" 2>/dev/null || echo "")
  if [ -n "$DETECTED_PUBLISH_NAME" ]; then
    AUTO_PROJECT_NAME=$(echo "$DETECTED_PUBLISH_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  elif [ -n "$DETECTED_BRAND" ]; then
    # Default: "{brand}-assessment" — clean, client-facing URL
    AUTO_PROJECT_NAME=$(echo "$DETECTED_BRAND-assessment" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
  fi
fi

# --- Interactive or headless ---
if [ $# -eq 0 ]; then
  # Interactive mode
  printf "${DIM}  Answer the prompts below. Press Enter to accept defaults.${RESET}\n"

  if [ -f .ux-audit.json ]; then
    printf "${DIM}  (Detected .ux-audit.json - using auto-detected values)${RESET}\n"
  fi
  echo ""

  prompt "Output directory" "$AUTO_OUTPUT_DIR" OUTPUT_DIR
  prompt_choice "Deploy provider" "vercel, netlify, surge" "vercel" PROVIDER
  prompt "URL slug (becomes {slug}.vercel.app)" "$AUTO_PROJECT_NAME" PROJECT_NAME
else
  # Headless mode - parse arguments
  OUTPUT_DIR=""
  PROVIDER="vercel"
  PROJECT_NAME=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --provider)
        PROVIDER="$2"
        shift 2
        ;;
      --provider=*)
        PROVIDER="${1#*=}"
        shift
        ;;
      --name)
        PROJECT_NAME="$2"
        shift 2
        ;;
      --name=*)
        PROJECT_NAME="${1#*=}"
        shift
        ;;
      -*)
        printf "${YELLOW}  Unknown option: %s${RESET}\n" "$1" >&2
        exit 1
        ;;
      *)
        OUTPUT_DIR="$1"
        shift
        ;;
    esac
  done

  # Apply auto-detected defaults for unset values
  if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="$AUTO_OUTPUT_DIR"
  fi
  if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="$AUTO_PROJECT_NAME"
  fi
fi

# --- Validate report exists ---
REPORT_FILE="$OUTPUT_DIR/ux-audit-report.html"
# Also check for index.html (the audits repo convention)
if [ ! -f "$REPORT_FILE" ] && [ -f "$OUTPUT_DIR/index.html" ]; then
  REPORT_FILE="$OUTPUT_DIR/index.html"
fi
if [ ! -f "$REPORT_FILE" ]; then
  echo ""
  printf "${YELLOW}  ✗ Report not found at %s${RESET}\n" "$OUTPUT_DIR" >&2
  printf "${YELLOW}    Run /ux-audit report first to generate it.${RESET}\n" >&2
  exit 1
fi

# --- Check prerequisites ---
check_vercel_auth() {
  printf "${DIM}  Checking Vercel setup...${RESET}\n"

  # Check if Vercel CLI is available
  if ! command -v vercel &>/dev/null && ! npx -y vercel --version &>/dev/null 2>&1; then
    printf "${YELLOW}  ⚠  Vercel CLI not found. Installing...${RESET}\n"
    npm install -g vercel 2>/dev/null || npx -y vercel --version >/dev/null 2>&1
    printf "${GREEN}  ✓  Installed.${RESET}\n"
  fi

  # Check if authenticated
  if ! npx -y vercel whoami &>/dev/null 2>&1; then
    echo ""
    printf "${YELLOW}  ⚠  Not authenticated with Vercel.${RESET}\n"
    echo ""
    printf "${BOLD}  To log in, you'll need your Vercel credentials.${RESET}\n"
    printf "${DIM}  These are in 1Password — search for \"Vercel\".${RESET}\n"
    printf "${DIM}  (Or ask your team lead for access.)${RESET}\n"
    echo ""
    printf "${BOLD}  Run this command, then re-run the publish script:${RESET}\n"
    echo ""
    printf "${CYAN}    npx vercel login${RESET}\n"
    echo ""
    exit 1
  fi

  VERCEL_USER=$(npx -y vercel whoami 2>/dev/null)
  printf "${GREEN}  ✓  Authenticated as ${BOLD}%s${RESET}\n" "$VERCEL_USER"
}

if [ "$PROVIDER" = "vercel" ]; then
  check_vercel_auth
fi
echo ""

# --- Summary ---
printf "${CYAN}${BOLD}  ── Deploy Configuration ───────────────────${RESET}\n"
printf "${BOLD}  Report:   ${RESET}%s\n" "$REPORT_FILE"
printf "${BOLD}  Provider: ${RESET}%s\n" "$PROVIDER"
printf "${BOLD}  URL slug: ${RESET}%s.vercel.app\n" "$PROJECT_NAME"
printf "${CYAN}  ─────────────────────────────────────────────${RESET}\n"
echo ""

# --- Create deploy directory ---
DEPLOY_DIR=$(mktemp -d)
trap 'rm -rf "$DEPLOY_DIR"' EXIT

# Copy report as index.html
cp "$REPORT_FILE" "$DEPLOY_DIR/index.html"

# Copy all assets alongside the report (images, video, CSS, SVGs)
for ASSET in "$OUTPUT_DIR"/*.{png,jpg,jpeg,webp,mp4,webm,svg,css}; do
  [ -f "$ASSET" ] && cp "$ASSET" "$DEPLOY_DIR/"
done

# --- Deploy ---
case "$PROVIDER" in
  vercel)
    printf "${BOLD}  Deploying to Vercel...${RESET}\n"
    VERCEL_OUTPUT=$(npx -y vercel deploy "$DEPLOY_DIR" --prod --yes 2>&1)
    VERCEL_URL=$(echo "$VERCEL_OUTPUT" | grep -oE 'https://[^ ]+\.vercel\.app' | tail -1)
    if [ -n "$VERCEL_URL" ]; then
      echo ""
      printf "${GREEN}${BOLD}  ✓ Live at: ${RESET}${BOLD}${VERCEL_URL}${RESET}\n"
    else
      echo "$VERCEL_OUTPUT"
      printf "${YELLOW}  ⚠  Deploy may have failed. Check output above.${RESET}\n"
    fi
    ;;
  netlify)
    printf "${BOLD}  Deploying to Netlify...${RESET}\n"
    npx -y netlify-cli deploy --prod --dir "$DEPLOY_DIR" --site "$PROJECT_NAME"
    ;;
  surge)
    printf "${BOLD}  Deploying to Surge...${RESET}\n"
    npx -y surge "$DEPLOY_DIR" "${PROJECT_NAME}.surge.sh"
    ;;
  *)
    printf "${YELLOW}  ✗ Unknown provider '%s'. Use: vercel, netlify, or surge${RESET}\n" "$PROVIDER" >&2
    exit 1
    ;;
esac

echo ""
printf "${GREEN}${BOLD}  Done.${RESET}\n"
echo ""
