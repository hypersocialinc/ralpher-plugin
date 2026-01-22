---
name: ralph-abandon
description: Abandon Ralph feature and clean up
---

# Ralph Abandon

Give up on the current Ralph feature and clean up tracking files.

## Process

### 1. Find Active Feature

Read `.ralph/active` to get the current feature name.

If file doesn't exist or is empty:
```
No active Ralph feature found.
Nothing to abandon.

Start a new feature with:
  /ralph-new <feature-name>
```

Validate the feature directory exists at `.ralph/<feature>/`.

### 2. Show Status

Read `.ralph/<feature>/prd.json` for context:
- Feature name
- Total stories
- Completed count
- Progress percentage

```
Ralph feature: <feature-name>
Progress: <completed>/<total> stories (<percentage>%)

Branch: ralph/<feature-name>
```

### 3. Confirm Abandonment

Ask for confirmation:

```
⚠️  Abandon this feature?

This will:
- Delete .ralph/<feature-name>/ directory
- Clear .ralph/active
- Keep the branch ralph/<feature-name> (you can delete it manually)
- Keep any commits made
- Lose all tracking/progress data

This cannot be undone.

Options:
1. Yes, abandon it
2. No, keep it
```

Use AskUserQuestion.

If "No", exit.

### 4. Stop Running Loop (if exists)

Check if a Ralph loop is running by looking for process signals:

```bash
# If running via terminal script, it will exit on next iteration
# when it can't find the feature directory
```

### 5. Delete Ralph Feature Directory

```bash
rm -rf .ralph/<feature>
```

### 6. Clear Active Feature

Remove the active feature marker:

```bash
rm .ralph/active
```

This clears the active feature state. The universal script `.ralph/ralph.sh` stays in place for future features.

### 7. Output Cleanup Instructions

```
✅ Abandoned Ralph feature: <feature-name>

Cleaned up:
- .ralph/<feature-name>/ (deleted)
- .ralph/active (cleared)

Branch ralph/<feature-name> still exists with commits.

To delete the branch:
git branch -D ralph/<feature-name>

To switch back to main:
git checkout main

To start a new feature:
/ralph-new <next-feature-name>
```

## Error Handling

If feature directory doesn't exist:
```
Error: .ralph/<feature-name>/ not found

The active file points to a missing feature.
Clearing .ralph/active...

Done. Run /ralph-new to start fresh.
```

If can't delete directory:
```
Error: Failed to delete .ralph/<feature-name>/

Permission error or files in use.
Try manually: rm -rf .ralph/<feature-name>
```

## Important Notes

- This is destructive - can't undo
- Always confirms before deleting
- Running loops will exit gracefully on next iteration
- Keeps the git branch (user can delete manually)
- Keeps any commits that were made
- Only deletes the .ralph tracking directory
- `.ralph/active` is cleared but `.ralph/ralph.sh` remains for future use
