---
name: ralph-go
description: Start Ralph autonomous loop via terminal script or current session
arguments: []
---

# Ralph Go

Start autonomous story execution for the active feature.

## Process

### 1. Find Active Feature

Read `.ralph/active` to get the current feature name.

If not found:
```
No active Ralph feature found.
Run /ralph-new <feature-name> first.
```

### 2. Show Status

Read `.ralph/{feature}/prd.json` and show progress:

```
Ralph: {feature}
Progress: {completed}/{total} stories

Ready to start autonomous execution.
```

### 3. Ask Execution Mode

Use AskUserQuestion:

**Option 1: Terminal Script (Recommended)**
```
Run .ralph/ralph.sh in a separate terminal
- Loops until all stories complete
- Can background, redirect to logs
- Works outside Claude Code
```

**Option 2: Autonomous (Current Session)**
```
Runs here with real-time progress
- See each story as it executes
- Max 20 iterations per session
```

### 4a. Terminal Script Mode

Output instructions (DO NOT run the script yourself):

```
📋 Open a new terminal and run:

  .ralph/ralph.sh

Options:
  .ralph/ralph.sh 50       # 50 iterations max
  .ralph/ralph.sh --hit    # Human-in-the-loop mode

The script will:
1. Call /ralph-next for each story
2. Parse exit signals
3. Stop when complete or blocked

When done: /ralph-done
```

### 4b. Autonomous Mode

Loop internally, calling the worker for each story:

```
for iteration in 1..20:

  Task(
    subagent_type: "ralph:ralph-worker",
    prompt: "Execute next story for feature: {feature}",
    description: "Ralph story {iteration}"
  )

  if result contains "RALPH_COMPLETE":
    break

  if result contains "RALPH_BLOCKED":
    show blocker, exit
```

### 5. Completion

**RALPH_COMPLETE:**
```
✅ All stories complete!

Feature: {feature}
Stories: {count}

Next: /ralph-done to create PR
```

**RALPH_BLOCKED:**
```
⚠️ Blocked - needs human intervention

Check: cat .ralph/{feature}/progress.txt
After fixing: /ralph-go to continue
```

## Script Location

The bash script lives at `.ralph/ralph.sh` (universal for all features).

If missing, copy from plugin templates:
```bash
cp ${CLAUDE_PLUGIN_ROOT}/templates/ralph-go.sh .ralph/ralph.sh
chmod +x .ralph/ralph.sh
```
