---
name: ralph-new
description: Start a new autonomous feature with Ralph
arguments:
  - name: feature-name
    description: Name of the feature (kebab-case)
    required: true
  - name: from
    description: Optional file path to existing spec/PRD
    required: false
    flag: --from
  - name: prompt
    description: Optional description/prompt for the feature
    required: false
    flag: --prompt
---

# Ralph New Feature

Initialize a new autonomous feature development loop with Ralph.

## Progress Markers

When running from the Ralpher desktop app, emit progress markers for UI updates:

```
RALPH_PROGRESS: branch_created      # After git branch created
RALPH_PROGRESS: scanning_codebase   # When planner starts exploring
RALPH_PROGRESS: generating_stories  # When planner generates prd.json
RALPH_PROGRESS: writing_files       # When .ralph/ files are written
RALPH_PROGRESS: committing          # When initial commit starts
RALPH_COMPLETE                      # All setup complete
RALPH_ERROR: <message>              # On any error
```

**Important:** Always output these markers on their own line so the desktop app can parse them.

## Process

### 1. Check for Existing Ralph

Look for `.ralph/active` file in the project root.

If it exists and points to a valid feature directory:
```
Found active Ralph feature: <name>
Options:
1. Complete it with /ralph-done
2. Abandon it with /ralph-abandon
3. Cancel this command
```

Use AskUserQuestion to get their choice. If they choose complete or abandon, remind them to run that command first.

### 2. Validate Feature Name

Feature name must be:
- Kebab-case (lowercase with hyphens)
- No spaces or special characters
- Example: `auth-system`, `payment-flow`, `user-dashboard`

### 3. Create Git Branch

```bash
git checkout -b ralph/<feature-name>
```

After branch is created, output:
```
RALPH_PROGRESS: branch_created
```

### 4. Create Ralph Directory Structure

```bash
mkdir -p .ralph/<feature-name>
```

### 5. Copy Templates

Copy from plugin templates to `.ralph/<feature-name>/`:
- `prd.json` (empty story list)
- `plan.md` (feature template)
- `progress.txt` (initialized log)

Replace template variables:
- `{{FEATURE_NAME}}` → feature name
- `{{DATE}}` → current date (YYYY-MM-DD)
- `{{STORY_COUNT}}` → 0 (will be filled by planner)

### 6. Set Up Universal Script (First Time Only)

Check if `.ralph/ralph.sh` exists. If not, create it:

```bash
cp ${CLAUDE_PLUGIN_ROOT}/templates/ralph-go.sh .ralph/ralph.sh
chmod +x .ralph/ralph.sh
```

This universal script:
- Reads active feature from `.ralph/active`
- Works for all current and future features
- Only created once per project

### 7. Set Active Feature

Write the feature name to the active file:

```bash
echo "<feature-name>" > .ralph/active
```

This marks this feature as the current active Ralph feature.

### 8. Handle Existing Spec or Prompt

**If user provided `--from <file>`:**
- Read the file
- Pass its contents to the ralph-planner agent
- Skip the Q&A phase (planner uses the doc instead)

**If user provided `--prompt "<text>"`:**
- Pass the prompt text to the ralph-planner agent
- Planner uses this as the initial feature description
- May ask follow-up questions if needed

### 9. Launch Ralph Planner

Use the Task tool to launch the `ralph-planner` agent:

```
Task tool:
  subagent_type: "ralph:ralph-planner"
  description: Plan feature and create stories
  prompt: |
    Feature name: <feature-name>
    Working directory: .ralph/<feature-name>

    {{If --from was used:}}
    Existing spec from file:
    <file contents>

    {{Else if --prompt was used:}}
    User's feature description:
    "<prompt text>"

    {{Otherwise:}}
    No existing spec - gather requirements from user.
```

The planner will:
- Ask user questions (or use provided spec)
- Generate `plan.md`
- Generate stories in `prd.json`
- Aim for 8-15 stories, 15-45 min each

### 10. Initialize Progress

After planner completes, update `progress.txt` with story count:
```
# Ralph Progress: <feature-name>
Branch: ralph/<feature-name>
Started: <date>

## Codebase Patterns
<!-- Add reusable patterns here as you discover them -->

---

## Log

=== <date> - Initialized ===
Feature: <feature-name>
Stories: <count from prd.json>
Ready to start.

---
```

### 11. Initial Commit

Output progress marker:
```
RALPH_PROGRESS: committing
```

Add all Ralph files:

```bash
git add .ralph/
git commit -m "ralph: init <feature-name>

<summary from plan.md>

Files:
- .ralph/<feature-name>/plan.md: Feature specification
- .ralph/<feature-name>/prd.json: <count> stories
- .ralph/<feature-name>/progress.txt: Work log
- .ralph/active: Points to <feature-name>
- .ralph/ralph.sh: Universal execution script (if new)

Co-Authored-By: Ralph <ralph@hypersocial.com>"
```

### 12. Output Instructions

First output the completion marker:
```
RALPH_COMPLETE
```

Then show the summary:
```
✅ Ralph feature initialized: <feature-name>

Files created:
- .ralph/<feature-name>/plan.md          # Feature specification
- .ralph/<feature-name>/prd.json         # Story definitions
- .ralph/<feature-name>/progress.txt     # Work log
- .ralph/active                          # Points to this feature
- .ralph/ralph.sh                        # Universal script (run from here)

Branch: ralph/<feature-name>
Stories: <count>

Next steps:

1. Review the plan:
   cat .ralph/<feature-name>/plan.md

2. Start development:

   Option A: Terminal Script (Recommended for CI/CD)
   .ralph/ralph.sh

   Options:
     .ralph/ralph.sh 50           # 50 iterations max
     .ralph/ralph.sh --hit        # Human-in-the-loop mode
     .ralph/ralph.sh 50 --hit     # Both

   Option B: Autonomous in Claude Code (Recommended for interactive)
   /ralph-go
   → Choose "Autonomous" when prompted

   Option C: One story at a time (Recommended for learning)
   /ralph-next

3. When complete:
   /ralph-done

Happy shipping!
```

## Error Handling

- If feature name invalid → show error with correct format
- If .ralph/active already exists → prompt for action
- If git operations fail → show error and cleanup
- If planner fails → cleanup .ralph directory and .ralph/active

## Important Notes

- Don't start the loop automatically - let user choose their mode
- The universal script lives at `.ralph/ralph.sh` (not per-feature)
- Always write `.ralph/active` to track the current feature
- Commit before suggesting next steps
