#!/usr/bin/env bash
# ==============================================================================
# Script: run_checks_terminals.sh
# Purpose: Run backend quality checks in separate terminals/tabs (GNOME Terminal)
# Checks:
#   1. pnpm build
#   2. pnpm exec tsc --noEmit
#   3. pnpm test
#   4. pnpm test:e2e
#   5. pnpm lint
#   6. pnpm format:check
# ==============================================================================

set -e

# 1. Resolve repository directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/../apps/server" ]; then
    REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -d "$SCRIPT_DIR/apps/server" ]; then
    REPO_ROOT="$SCRIPT_DIR"
else
    REPO_ROOT="$(pwd)"
fi

SERVER_DIR="$REPO_ROOT/apps/server"

if [ ! -d "$SERVER_DIR" ]; then
    echo "❌ Error: apps/server directory not found at $SERVER_DIR"
    exit 1
fi

# 2. Setup PATH for Node.js and pnpm
NODE_PATHS=""
if [ -d "$HOME/.nvm/versions/node" ]; then
    LATEST_NVM_BIN=$(find "$HOME/.nvm/versions/node" -maxdepth 2 -name bin 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$LATEST_NVM_BIN" ]; then
        NODE_PATHS="$LATEST_NVM_BIN:"
    fi
fi
if [ -d "$HOME/.local/share/pnpm" ]; then
    NODE_PATHS="${NODE_PATHS}$HOME/.local/share/pnpm/bin:"
fi

ENV_EXPORTS="export PATH=\"${NODE_PATHS}\$PATH\""

# 3. Helper to wrap check commands with status banner and pause
create_runner_cmd() {
    local title="$1"
    local cmd="$2"

    cat <<EOF
$ENV_EXPORTS
cd "$SERVER_DIR"
echo -e "\033[1;36m============================================================\033[0m"
echo -e "\033[1;36m  🚀 Running: $title\033[0m"
echo -e "\033[1;33m  Command:  $cmd\033[0m"
echo -e "\033[1;36m============================================================\033[0m"
echo ""

START_TIME=\$(date +%s)
set +e
$cmd
EXIT_CODE=\$?
set -e
END_TIME=\$(date +%s)
DURATION=\$((END_TIME - START_TIME))

echo ""
echo -e "\033[1;36m------------------------------------------------------------\033[0m"
if [ \$EXIT_CODE -eq 0 ]; then
    echo -e "\033[1;32m  ✅ [PASSED] $title (Duration: \${DURATION}s)\033[0m"
else
    echo -e "\033[1;31m  ❌ [FAILED] $title (Exit Code: \$EXIT_CODE, Duration: \${DURATION}s)\033[0m"
fi
echo -e "\033[1;36m------------------------------------------------------------\033[0m"
echo ""
echo "Press [Enter] or close window to exit..."
read -r
EOF
}

CMD1=$(create_runner_cmd "1. Nest Build" "pnpm build")
CMD2=$(create_runner_cmd "2. TypeScript Check" "pnpm exec tsc --noEmit")
CMD3=$(create_runner_cmd "3. Unit & Integration Tests" "pnpm test")
CMD4=$(create_runner_cmd "4. E2E Tests" "pnpm test:e2e")
CMD5=$(create_runner_cmd "5. ESLint" "pnpm lint")
CMD6=$(create_runner_cmd "6. Prettier Format Check" "pnpm format:check")

MODE="${1:-tabs}"

echo "============================================================"
echo "  Subscription Track: Multi-Terminal Quality Checker"
echo "============================================================"
echo "Directory: $SERVER_DIR"
echo "Mode:      $MODE"
echo ""

# Check if GUI display is available
if [ -z "$DISPLAY" ] && [ "$MODE" != "headless" ]; then
    echo "⚠️  No graphical DISPLAY detected (\$DISPLAY is empty)."
    echo "    Switching to parallel headless runner..."
    MODE="headless"
fi

if [ "$MODE" = "windows" ] && command -v gnome-terminal >/dev/null 2>&1; then
    echo "🚀 Launching 6 separate GNOME Terminal windows..."
    gnome-terminal --title="1. Build" -- bash -c "$CMD1" &
    gnome-terminal --title="2. TypeCheck" -- bash -c "$CMD2" &
    gnome-terminal --title="3. Tests" -- bash -c "$CMD3" &
    gnome-terminal --title="4. E2E Tests" -- bash -c "$CMD4" &
    gnome-terminal --title="5. Lint" -- bash -c "$CMD5" &
    gnome-terminal --title="6. Format Check" -- bash -c "$CMD6" &
    echo "✅ All 6 terminal windows launched!"

elif [ "$MODE" = "tabs" ] && command -v gnome-terminal >/dev/null 2>&1; then
    echo "🚀 Launching GNOME Terminal with 6 tabs in a single window..."
    gnome-terminal \
        --tab --title="1. Build" -- bash -c "$CMD1" \
        --tab --title="2. TypeCheck" -- bash -c "$CMD2" \
        --tab --title="3. Tests" -- bash -c "$CMD3" \
        --tab --title="4. E2E" -- bash -c "$CMD4" \
        --tab --title="5. Lint" -- bash -c "$CMD5" \
        --tab --title="6. Format" -- bash -c "$CMD6" &
    echo "✅ GNOME Terminal window with 6 tabs launched!"

elif [ "$MODE" = "tmux" ] && command -v tmux >/dev/null 2>&1; then
    echo "🚀 Launching tmux session 'checks' with grid layout..."
    SESSION="checks_$(date +%s)"
    tmux new-session -d -s "$SESSION" -n "quality-checks" "bash -c '$CMD1'"
    tmux split-window -t "$SESSION:0" -h "bash -c '$CMD2'"
    tmux split-window -t "$SESSION:0.0" -v "bash -c '$CMD3'"
    tmux split-window -t "$SESSION:0.1" -v "bash -c '$CMD4'"
    tmux split-window -t "$SESSION:0.2" -v "bash -c '$CMD5'"
    tmux split-window -t "$SESSION:0.3" -v "bash -c '$CMD6'"
    tmux select-layout -t "$SESSION:0" tiled
    tmux attach-session -t "$SESSION"

else
    echo "ℹ️  Running checks concurrently in the current terminal (headless mode)..."
    echo ""
    eval "$ENV_EXPORTS"
    cd "$SERVER_DIR"

    run_with_prefix() {
        local name="$1"
        local color="$2"
        local cmd="$3"
        bash -c "$cmd" 2>&1 | while IFS= read -r line; do
            echo -e "\033[${color}m[${name}]\033[0m $line"
        done
    }

    run_with_prefix "BUILD" "1;34" "pnpm build" &
    PID1=$!
    run_with_prefix "TSC" "1;36" "pnpm exec tsc --noEmit" &
    PID2=$!
    run_with_prefix "TEST" "1;32" "pnpm test" &
    PID3=$!
    run_with_prefix "E2E" "1;35" "pnpm test:e2e" &
    PID4=$!
    run_with_prefix "LINT" "1;33" "pnpm lint" &
    PID5=$!
    run_with_prefix "FORMAT" "1;37" "pnpm format:check" &
    PID6=$!

    wait $PID1 && echo "✅ BUILD finished successfully" || echo "❌ BUILD failed"
    wait $PID2 && echo "✅ TSC finished successfully" || echo "❌ TSC failed"
    wait $PID3 && echo "✅ TEST finished successfully" || echo "❌ TEST failed"
    wait $PID4 && echo "✅ E2E finished successfully" || echo "❌ E2E failed"
    wait $PID5 && echo "✅ LINT finished successfully" || echo "❌ LINT failed"
    wait $PID6 && echo "✅ FORMAT finished successfully" || echo "❌ FORMAT failed"
fi
