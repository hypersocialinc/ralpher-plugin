---
name: ralph-done
description: Complete Ralph feature, archive, and create PR
---

# Ralph Done

Complete the Ralph feature, archive tracking files, and create a PR to main.

## Process

### 1. Find Active Feature

Read `.ralph/active` to get the current feature name.

If file doesn't exist or is empty:
```
No active Ralph feature found.
Nothing to complete.

Start a new feature with:
  /ralph-new <feature-name>
```

Validate the feature directory exists at `.ralph/<feature>/`.

### 2. Check Completion

Read `.ralph/<feature>/prd.json` and check all stories.

Count stories by status:
- Total: all stories
- Completed: `status === "completed"`
- Incomplete: any other status

If incomplete stories exist:
```
⚠️  Feature not complete

Progress: <completed>/<total> stories (<percentage>%)

Incomplete stories:
- <id>: <title> (status: <status>)
- <id>: <title> (status: <status>)

Options:
1. Complete remaining stories with /ralph-next
2. Mark feature done anyway (incomplete)
3. Abandon with /ralph-abandon
```

Use AskUserQuestion to get their choice.

If they choose "mark done anyway", continue. Otherwise exit.

### 3. Final Review

Run a final review of all changes vs main branch:

```bash
git diff main...HEAD
```

Launch parallel review agents on the full diff:
```
Task tool (parallel):
  1. subagent: code-reviewer (review all changes)
  2. subagent: silent-failure-hunter (check error handling)
```

If critical issues found:
```
⚠️  Review found critical issues:

<list issues>

Options:
1. Fix issues first (recommended)
2. Create PR anyway
3. Cancel
```

Use AskUserQuestion.

### 4. Generate Summary

Create `.ralph/<feature>/summary.md`:

```markdown
# Ralph Summary: <feature-name>

## Overview
Feature: <feature-name>
Branch: ralph/<feature-name>
Started: <from progress.txt>
Completed: <current date>

## Stories Completed
<total> / <total> stories (<percentage>%)

<for each completed story:>
- ✅ <id>: <title>

<if any incomplete:>
## Incomplete Stories
- ⏸️ <id>: <title> (status: <status>)

## Key Patterns Learned

<extract from Codebase Patterns section of progress.txt>

## Files Changed

<list files from git diff --name-only main...HEAD>

## Commits

<list commits from git log main...HEAD --oneline>

## Time Spent

<parse timestamps from progress.txt, calculate rough duration>
Estimated: <hours> hours over <days> days
```

### 5. Archive Ralph Directory

```bash
mkdir -p .ralph-archive
mv .ralph/<feature> .ralph-archive/<feature>
```

### 6. Clear Active Feature

Remove the active feature marker:

```bash
rm .ralph/active
```

This clears the active feature state. The universal script `.ralph/ralph.sh` stays in place for future features.

### 7. Commit Archive

```bash
git add .ralph-archive/<feature>
git add .ralph/  # Remove .ralph/<feature> and .ralph/active
git commit -m "ralph: archive <feature-name>

<summary from summary.md>

Stories: <completed>/<total>
Commits: <count>

Co-Authored-By: Ralph <ralph@hypersocial.com>"
```

### 8. Create PR

Use `gh pr create`:

```bash
gh pr create \
  --title "feat: <feature-name>" \
  --body "$(cat .ralph-archive/<feature>/summary.md)" \
  --base main \
  --head ralph/<feature>
```

If `gh` not available:
```
gh CLI not found. Create PR manually:
- Base: main
- Head: ralph/<feature>
- Use .ralph-archive/<feature>/summary.md as description
```

### 9. Output Success

```
✅ Ralph feature complete: <feature-name>

Summary: .ralph-archive/<feature>/summary.md

PR created: <PR URL>

Branch ralph/<feature> can be deleted after PR merges.

Next:
- Review the PR
- Merge when ready
- Delete branch after merge

To start a new feature:
  /ralph-new <next-feature-name>
```

## Error Handling

If `gh pr create` fails:
- Show instructions for manual PR creation
- Provide summary.md path
- Don't fail the whole process

If git operations fail:
- Show error
- Don't cleanup (let user recover)

## Important Notes

- Always create summary.md for posterity
- Archive preserves full history
- PR description includes learned patterns
- Branch stays for review (deleted after merge)
- Final review catches last-minute issues
- `.ralph/active` is cleared but `.ralph/ralph.sh` remains
