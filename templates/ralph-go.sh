#!/bin/bash
# Ralph - Autonomous Story Execution (with Parallel Workers)
#
# Usage:
#   ./ralph.sh              # Run with defaults (20 iterations, 3 parallel workers)
#   ./ralph.sh 50           # Run 50 iterations max
#   ./ralph.sh --parallel 5 # Run 5 workers in parallel
#   ./ralph.sh --hit        # Human-in-the-loop mode (disables parallel)
#   ./ralph.sh 50 --parallel 5 --hit  # All options
#
# Modes:
#   - Default: Parallel execution with dispatcher
#   - --hit: Human-in-the-loop, sequential execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Parse arguments
MAX_ITERATIONS=20
MAX_WORKERS=3
HUMAN_IN_LOOP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --hit|--human-in-loop)
      HUMAN_IN_LOOP=true
      shift
      ;;
    --parallel)
      MAX_WORKERS=$2
      shift 2
      ;;
    [0-9]*)
      MAX_ITERATIONS=$1
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: ./ralph.sh [max_iterations] [--parallel N] [--hit]"
      exit 1
      ;;
  esac
done

cd "$PROJECT_ROOT"

# Check for active feature
if [ ! -f ".ralph/active" ]; then
  echo "❌ No active Ralph feature"
  echo "   Run: claude /ralph-new <feature-name>"
  exit 1
fi

FEATURE=$(cat .ralph/active)
if [ -z "$FEATURE" ] || [ ! -d ".ralph/$FEATURE" ]; then
  echo "❌ Invalid feature in .ralph/active"
  exit 1
fi

FEATURE_DIR=".ralph/$FEATURE"

# Check claude CLI
if ! command -v claude &> /dev/null; then
  echo "❌ Claude CLI not found"
  echo "   Install: https://docs.anthropic.com/cli"
  exit 1
fi

# Create logs directory
mkdir -p "$FEATURE_DIR/logs"

# Header
echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  🚀 RALPH                                      ┃"
echo "┃  Feature: $FEATURE"
echo "┃  Max iterations: $MAX_ITERATIONS"
if [ "$HUMAN_IN_LOOP" = true ]; then
echo "┃  Mode: Human-in-the-loop (sequential)         ┃"
else
echo "┃  Mode: Autonomous (parallel, $MAX_WORKERS workers)      ┃"
fi
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# Temp file for output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Function to run a single worker for a story
run_worker() {
  local STORY_ID=$1
  local LOG_FILE="$FEATURE_DIR/logs/${STORY_ID}.log"

  echo "[Worker $STORY_ID] Starting..." >> "$LOG_FILE"

  if [ "$HUMAN_IN_LOOP" = true ]; then
    claude /ralph-next "$STORY_ID" >> "$LOG_FILE" 2>&1
  else
    claude --dangerously-skip-permissions /ralph-next "$STORY_ID" >> "$LOG_FILE" 2>&1
  fi

  local EXIT_CODE=$?
  echo "[Worker $STORY_ID] Completed with exit code: $EXIT_CODE" >> "$LOG_FILE"
  return $EXIT_CODE
}

# Human-in-the-loop mode: sequential execution (original behavior)
if [ "$HUMAN_IN_LOOP" = true ]; then
  echo "Running in sequential mode..."
  echo ""

  for i in $(seq 1 $MAX_ITERATIONS); do
    echo "━━━ Story $i/$MAX_ITERATIONS ━━━"
    echo ""

    # Run one story
    set +e
    claude /ralph-next 2>&1 | tee "$TEMP_OUTPUT"
    EXIT_CODE=${PIPESTATUS[0]}
    OUTPUT=$(cat "$TEMP_OUTPUT")
    set -e

    # Parse signals
    if echo "$OUTPUT" | grep -q "RALPH_COMPLETE"; then
      echo ""
      echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
      echo "┃  ✅ ALL STORIES COMPLETE                      ┃"
      echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
      echo ""
      echo "Next: claude /ralph-done"
      exit 0
    fi

    if echo "$OUTPUT" | grep -q "RALPH_BLOCKED"; then
      echo ""
      echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
      echo "┃  ⚠️  BLOCKED - Needs human intervention       ┃"
      echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
      echo ""
      echo "Check: cat .ralph/$FEATURE/progress.txt"
      exit 1
    fi

    if echo "$OUTPUT" | grep -q "RALPH_ERROR"; then
      echo ""
      echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
      echo "┃  ❌ ERROR                                     ┃"
      echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
      echo ""
      exit 1
    fi

    if [ $EXIT_CODE -ne 0 ]; then
      echo ""
      echo "❌ Command failed (exit: $EXIT_CODE)"
      echo "   Retry: ./ralph.sh --hit"
      exit $EXIT_CODE
    fi

    echo ""
    echo "✓ Iteration $i complete"
    echo ""
    sleep 2
  done

  echo ""
  echo "⏸️  Max iterations reached ($MAX_ITERATIONS)"
  echo "   Continue: ./ralph.sh --hit"
  exit 0
fi

# Parallel mode: use dispatcher to batch stories
echo "Running in parallel mode with dispatcher..."
echo ""

for iteration in $(seq 1 $MAX_ITERATIONS); do
  echo "━━━ Iteration $iteration/$MAX_ITERATIONS ━━━"
  echo ""

  # Step 1: Run dispatcher to get batch of ready stories
  echo "📋 Dispatcher analyzing stories..."

  set +e
  BATCH=$(claude --dangerously-skip-permissions \
    -p "Read $FEATURE_DIR/prd.json. Find stories with status not_started where all dependencies are completed. Return JSON array of up to $MAX_WORKERS story IDs sorted by priority. Output ONLY the JSON array, nothing else." \
    2>/dev/null | grep -o '\[.*\]' | head -1)
  set -e

  echo "   Batch: $BATCH"

  # Check if empty batch
  if [ "$BATCH" = "[]" ] || [ -z "$BATCH" ]; then
    # Check if all completed or blocked
    echo "   No ready stories found, checking status..."

    set +e
    PENDING_COUNT=$(claude --dangerously-skip-permissions \
      -p "Read $FEATURE_DIR/prd.json. Count stories with status not_started. Output ONLY the number." \
      2>/dev/null | grep -o '[0-9]*' | head -1)
    set -e

    if [ "$PENDING_COUNT" = "0" ] || [ -z "$PENDING_COUNT" ]; then
      echo ""
      echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
      echo "┃  ✅ ALL STORIES COMPLETE                      ┃"
      echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
      echo ""
      echo "Next: claude /ralph-done"
      exit 0
    else
      echo ""
      echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
      echo "┃  ⚠️  BLOCKED - Stories waiting on dependencies┃"
      echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
      echo ""
      echo "Check: cat .ralph/$FEATURE/progress.txt"
      exit 1
    fi
  fi

  # Step 2: Parse batch and spawn workers in parallel
  # Remove brackets and quotes, convert commas to spaces
  STORY_IDS=$(echo "$BATCH" | tr -d '[]"' | tr ',' ' ')
  WORKER_COUNT=0

  # Mark all stories in batch as in_progress BEFORE spawning workers
  # This gives immediate UI feedback
  for STORY_ID in $STORY_IDS; do
    STORY_ID=$(echo "$STORY_ID" | tr -d ' ')
    [ -z "$STORY_ID" ] && continue

    # Update prd.json to mark story as in_progress
    if command -v jq &> /dev/null; then
      jq --arg id "$STORY_ID" \
        '.stories |= map(if .id == $id then .status = "in_progress" else . end)' \
        "$FEATURE_DIR/prd.json" > "$FEATURE_DIR/prd.json.tmp" && \
        mv "$FEATURE_DIR/prd.json.tmp" "$FEATURE_DIR/prd.json"
    fi
  done

  for STORY_ID in $STORY_IDS; do
    # Trim whitespace
    STORY_ID=$(echo "$STORY_ID" | tr -d ' ')
    [ -z "$STORY_ID" ] && continue

    echo "🔧 Spawning worker for $STORY_ID"
    WORKER_COUNT=$((WORKER_COUNT + 1))

    # Run worker in background
    (
      LOG_FILE="$FEATURE_DIR/logs/${STORY_ID}.log"
      echo "=== Worker started at $(date) ===" > "$LOG_FILE"

      claude --dangerously-skip-permissions \
        /ralph-next "$STORY_ID" >> "$LOG_FILE" 2>&1

      echo "=== Worker finished at $(date) ===" >> "$LOG_FILE"
    ) &
  done

  # Step 3: Wait for all workers to complete
  if [ $WORKER_COUNT -gt 0 ]; then
    echo ""
    echo "⏳ Waiting for $WORKER_COUNT worker(s)..."
    wait
    echo "   All workers complete"
  fi

  # Brief pause before next iteration
  echo ""
  echo "✓ Iteration $iteration complete"
  echo ""
  sleep 2
done

echo ""
echo "⏸️  Max iterations reached ($MAX_ITERATIONS)"
echo "   Continue: ./ralph.sh"
echo "   Status: claude /ralph-status"
exit 0
