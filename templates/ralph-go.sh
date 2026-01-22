#!/bin/bash
# Ralph - Autonomous Story Execution
#
# Usage:
#   ./ralph.sh              # Run with defaults (20 iterations)
#   ./ralph.sh 50           # Run 50 iterations max
#   ./ralph.sh --hit        # Human-in-the-loop mode
#   ./ralph.sh 50 --hit     # Both

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
MAX_ITERATIONS=20
HUMAN_IN_LOOP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --hit|--human-in-loop)
      HUMAN_IN_LOOP=true
      shift
      ;;
    [0-9]*)
      MAX_ITERATIONS=$1
      shift
      ;;
    *)
      echo "Unknown option: $1"
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

# Check claude CLI
if ! command -v claude &> /dev/null; then
  echo "❌ Claude CLI not found"
  echo "   Install: https://docs.anthropic.com/cli"
  exit 1
fi

# Header
echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃  🚀 RALPH                                      ┃"
echo "┃  Feature: $FEATURE"
echo "┃  Max iterations: $MAX_ITERATIONS"
if [ "$HUMAN_IN_LOOP" = true ]; then
echo "┃  Mode: Human-in-the-loop                      ┃"
else
echo "┃  Mode: Autonomous                             ┃"
fi
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# Temp file for output
TEMP_OUTPUT=$(mktemp)
trap "rm -f $TEMP_OUTPUT" EXIT

# Main loop
for i in $(seq 1 $MAX_ITERATIONS); do
  echo "━━━ Story $i/$MAX_ITERATIONS ━━━"
  echo ""

  # Run one story
  set +e
  if [ "$HUMAN_IN_LOOP" = true ]; then
    claude /ralph-next 2>&1 | tee "$TEMP_OUTPUT"
  else
    claude --dangerously-skip-permissions /ralph-next 2>&1 | tee "$TEMP_OUTPUT"
  fi
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
    echo "   Retry: ./ralph.sh"
    exit $EXIT_CODE
  fi

  # STORY_COMPLETE or STORY_STUCK - continue to next
  echo ""
  echo "✓ Iteration $i complete"
  echo ""
  sleep 2
done

echo ""
echo "⏸️  Max iterations reached ($MAX_ITERATIONS)"
echo "   Continue: ./ralph.sh"
echo "   Status: claude /ralph-status"
exit 0
