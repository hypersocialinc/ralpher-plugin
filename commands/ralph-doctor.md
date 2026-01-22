---
name: ralph-doctor
description: Check and repair Ralph project health
arguments:
  - name: feature
    description: Feature name to check (optional, defaults to active feature)
    required: false
---

Run a health check on a Ralph feature and fix common issues.

## Tasks

1. **Locate the feature**
   - If `feature` arg provided, check `.ralph/{feature}/`
   - Otherwise, read `.ralph/active` for the current feature
   - If `.ralph/active` doesn't exist or is empty, show error and suggest `/ralph-new`

2. **Validate file structure**
   Check that all required files exist:
   - `.ralph/{feature}/plan.md` - Feature specification
   - `.ralph/{feature}/prd.json` - Stories with status
   - `.ralph/{feature}/progress.txt` - Work log

   Also check for universal script:
   - `.ralph/ralph.sh` - Universal execution script

   If `.ralph/ralph.sh` is missing:
   - Offer to generate it from template
   - Copy from `${CLAUDE_PLUGIN_ROOT}/templates/ralph-go.sh`
   - Make executable with `chmod +x`

   Report any missing files.

3. **Validate .ralph/active state**
   Check that `.ralph/active` contains a valid feature name:
   - File exists
   - Contents match an existing feature directory
   - Not pointing to a deleted feature

   If invalid, offer to fix by:
   - Clearing `.ralph/active` if feature doesn't exist
   - Setting it to the detected feature if only one exists

4. **Validate prd.json structure**
   Check that `prd.json` has:
   - Valid JSON syntax
   - `stories` array
   - Each story has: id, title, steps, passes, dependencies, priority, status
   - Valid status values: "not_started", "in_progress", "completed", "blocked"

   Report any issues found.

5. **Check for stale or blocked stories**
   - Count stories by status
   - Identify stories marked "blocked" and show their blockers
   - Identify stories with "in_progress" status but no recent STARTED timestamp in progress.txt

   These may indicate crashed iterations or forgotten work.

6. **Verify git branch**
   - Check if current branch matches the feature name pattern
   - Warn if on main/master branch (Ralph should work on feature branches)

7. **Check for orphaned files**
   - Look for old per-feature `ralph-go.sh` files inside `.ralph/{feature}/`
   - Look for old `claude.md` files (from old bash-based architecture)
   - Offer to remove them since we now use universal `.ralph/ralph.sh`

8. **Report and offer fixes**
   Provide a clear report:
   ```
   🏥 Ralph Doctor Report: {feature}

   ✅ File structure: OK
   ✅ prd.json: Valid (12 stories, 7 complete, 1 blocked, 4 pending)
   ✅ .ralph/active: Points to {feature}
   ✅ Universal script: .ralph/ralph.sh exists
   ⚠️  Git branch: Currently on 'main' (recommend feature branch)
   ⚠️  Orphaned files: .ralph/{feature}/ralph-go.sh (old per-feature script)

   Issues Found:
   1. Story FEAT-005 blocked: "Waiting for API keys"
   2. Working on main branch - recommend: git checkout ralph/{feature}
   3. Old per-feature script found - can use universal script instead

   Recommended Actions:
   - Resolve blocker for FEAT-005
   - Switch to feature branch
   - Remove orphaned per-feature script
   ```

9. **Auto-fix options**
   Offer to automatically fix issues:
   - Create proper feature branch and switch to it
   - Remove orphaned files from old architecture
   - Fix `.ralph/active` if pointing to invalid feature
   - Generate missing `.ralph/ralph.sh`
   - Fix malformed prd.json (if possible)

   Ask user which fixes to apply, then execute them.

10. **Summary**
    End with next steps:
    - If healthy: "✅ Ralph project is healthy! Run /ralph-next or /ralph-go to resume work."
    - If fixed: "✅ Issues fixed! Run /ralph-doctor again to verify, then /ralph-next to resume."
    - If issues remain: "⚠️  Manual intervention needed. See report above."

## Example Output

```
🏥 Running Ralph Doctor...

Active feature (from .ralph/active): hypersketcher-mvp

📋 Checking file structure...
✅ plan.md exists
✅ prd.json exists
✅ progress.txt exists
✅ .ralph/ralph.sh exists (universal script)
⚠️  Found orphaned file: .ralph/hypersketcher-mvp/ralph-go.sh (old per-feature script)

🔍 Analyzing prd.json...
✅ Valid JSON structure
📊 Stories: 15 total (8 complete, 1 in_progress, 1 blocked, 5 pending)
⚠️  Blocked story: MVP-009 - "Need design assets for landing page"

🔍 Checking git status...
⚠️  Currently on branch 'main' (recommend feature branch)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issues found: 2

1. Old per-feature script present
   - .ralph/hypersketcher-mvp/ralph-go.sh (no longer needed)
   - Use .ralph/ralph.sh instead

2. Working on main branch
   - Ralph should work on feature branches
   - Prevents accidental commits to main

Auto-fixable: Yes

Would you like me to:
1. Remove orphaned per-feature script
2. Switch to feature branch 'ralph/hypersketcher-mvp'

Apply fixes? (yes/no)
```

## Orphaned File Detection

Ralph now uses a **universal script** at `.ralph/ralph.sh` that reads the active feature from `.ralph/active`.

The old approach created per-feature scripts:
- `.ralph/{feature}/ralph-go.sh` - No longer needed

These files are no longer needed and can be safely removed. The new architecture uses:
- `.ralph/ralph.sh` - Universal script (works for any feature)
- `.ralph/active` - Tracks current feature name
- Commands that spawn agents (/ralph-go, /ralph-next)

## Notes

- This command is safe to run anytime - it only reads and reports by default
- Always ask before making changes (removing files, creating branches, etc.)
- If user says yes to fixes, apply them and re-run the health check to confirm
- The universal script approach is simpler - one script for all features
