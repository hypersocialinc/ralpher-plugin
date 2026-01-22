---
name: ralph-next
description: Execute one Ralph story interactively
arguments: []
---

# Ralph Next

Execute the next story for the active Ralph feature.

## Process

### 1. Find Active Feature

Read `.ralph/active` to get the current feature name.

If file doesn't exist or is empty:
```
No active Ralph feature found.
Run /ralph-new <feature-name> to start one.
```

### 2. Validate Feature Directory

Check that `.ralph/{feature}/` exists with:
- `prd.json`
- `progress.txt`

If missing:
```
Feature directory incomplete: .ralph/{feature}/
Run /ralph-doctor to diagnose.
```

### 3. Spawn Worker

Use the Task tool to launch the ralph-worker agent:

```
Task(
  subagent_type: "ralph:ralph-worker",
  prompt: "Execute next story for feature: {feature}",
  description: "Ralph story: {feature}"
)
```

### 4. Return Result

Pass through the worker's exit signal:

- `RALPH_COMPLETE` → All stories done
- `STORY_COMPLETE: {id}` → Story done, more remain
- `STORY_STUCK: {id}` → Story needs fresh attempt
- `RALPH_BLOCKED: {reason}` → Needs human intervention
- `RALPH_ERROR: {message}` → Unexpected error

The bash script parses these signals to decide whether to continue.

## Usage

**Interactive (one story at a time):**
```
/ralph-next
```

**Via bash script (autonomous loop):**
```bash
.ralph/ralph.sh
```

The bash script calls `/ralph-next` repeatedly until all stories are done.

## What the Worker Does

The ralph-worker agent handles everything:

1. Reads prd.json, picks next story
2. Spawns design agent (if frontend)
3. Loads skills (if specified)
4. Implements the story
5. Runs typecheck (loops until passes)
6. Runs review agents (mandatory)
7. Fixes issues (loops until clean)
8. Runs tests (if available)
9. Commits
10. Updates progress

You just invoke `/ralph-next` - the worker handles the rest.
