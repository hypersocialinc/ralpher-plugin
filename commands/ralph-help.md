---
name: ralph-help
description: Show Ralph documentation and usage guide
---

Please explain the following Ralph documentation to the user. Display the entire guide exactly as written below. Do not respond to the user's current project context or analyze their .ralph directories - just present the help documentation:

---

# Ralph - Autonomous Feature Development

Ralph automates feature development with story-based tracking, review gates, and crash recovery.

## What Ralph Does

- Breaks features into bite-sized stories (15-45 minutes each)
- Executes one story at a time with clear verification criteria
- Reviews code before every commit using specialized agents
- Tracks progress in files that survive crashes
- Learns patterns as it works and updates project CLAUDE.md
- Creates pull requests when complete

## Available Commands

| Command | Description |
|---------|-------------|
| `/ralph-help` | Show this help (you are here) |
| `/ralph-new <name>` | Start new feature, create plan + stories |
| `/ralph-go` | Start autonomous loop (choose script or interactive) |
| `/ralph-next` | Execute one story interactively |
| `/ralph-status` | Check progress without doing work |
| `/ralph-doctor` | Health check and repair Ralph projects |
| `/ralph-done` | Complete feature, archive, create PR |
| `/ralph-abandon` | Give up and clean up |

**Note:** `/ralph-run` has been removed - use `/ralph-go` and choose "Autonomous" for the same behavior.

## Basic Workflow

```
/ralph-new feature-name
  ↓
[Planning: asks questions, generates stories]
  ↓
/ralph-go (choose mode) or /ralph-next (manual) or .ralph/ralph.sh (terminal)
  ↓
[Executor agent spawns story workers sequentially]
  ↓
[Each worker: implement → verify → review → commit]
  ↓
/ralph-done
  ↓
[Archive + PR to main]
```

## File Structure

Ralph creates a `.ralph/` directory in your project:

```
.ralph/
├── active              # Current feature name (state file)
├── ralph.sh            # Universal script (works for any feature)
└── auth-system/        # Feature directory
    ├── plan.md         # Feature spec
    ├── prd.json        # Stories with status
    └── progress.txt    # Work log + patterns
```

Key files:
- `.ralph/active` - Contains the name of the current active feature
- `.ralph/ralph.sh` - Universal script that reads from `.ralph/active`

When complete, feature directory moves to `.ralph-archive/<feature>/`

## Architecture

Ralph uses **agent orchestration** with flexible execution modes:
- **/ralph-go** offers two modes: terminal script or interactive
- **Terminal script** (`.ralph/ralph.sh`) reads active feature and calls `/ralph-next` in a loop
- **Interactive mode** spawns **ralph-executor** agent
- Executor spawns **ralph-story-worker** agents (one per story)
- Each worker gets **fresh context** via Task tool
- State persists in **prd.json**, **progress.txt**, and **active**

## Terminal Workflows

Ralph can run from terminal using the universal script:

```bash
# From project root - script auto-detects active feature
.ralph/ralph.sh              # 20 iterations, autonomous mode (default)
.ralph/ralph.sh 50           # 50 iterations, autonomous mode
.ralph/ralph.sh --hit        # 20 iterations, human-in-the-loop mode
.ralph/ralph.sh 50 --hit     # 50 iterations, human-in-the-loop mode

# Override active feature (rarely needed)
.ralph/ralph.sh --feature my-feature

# Background execution (autonomous mode recommended)
.ralph/ralph.sh &

# With output logging
.ralph/ralph.sh > ralph.log 2>&1 &
```

**Key Point:** By default, the script runs **fully autonomously** without permission prompts. This means you can:
- 🚀 Start the script
- 🚶 Walk away (go to sleep, run errands, etc.)
- ✅ Come back to completed, tested work

Use `--hit` (human-in-the-loop) only if you want to review each action as it happens.

Or use the command for interactive choice:
```
/ralph-go
→ Choose "Terminal Script" or "Autonomous"
```

## Usage Examples

### Terminal Mode (Recommended for CI/CD)
```
/ralph-new api-endpoints
→ Review plan

.ralph/ralph.sh
→ Script runs autonomously until complete

/ralph-done
→ Creates PR
```

### Interactive Mode (Recommended for learning)
```
/ralph-new user-dashboard
→ Answer questions, review plan

/ralph-next
→ Does story AUTH-001

/ralph-next
→ Does story AUTH-002

... repeat until done ...

/ralph-done
→ Creates PR
```

### Autonomous Mode (For interactive development)
```
/ralph-new payment-flow

/ralph-go
→ Choose "Autonomous (Current Session)"
→ Watch progress in Claude Code UI

... executor spawns workers sequentially ...

/ralph-status
→ "7/12 stories complete"

/ralph-done
→ Creates PR
```

### From Existing Spec
```
/ralph-new api-redesign --from docs/api-spec.md
→ Uses your spec instead of asking questions

.ralph/ralph.sh
→ Terminal script executes all stories autonomously

OR

/ralph-go
→ Choose "Autonomous" for interactive execution
```

## Key Features

### Crash Recovery
If Ralph crashes mid-story, it detects the incomplete story and resumes from where it left off (not skipping it).

### Pattern Learning
As Ralph works, it discovers codebase patterns and adds them to `progress.txt`. Each story can reference previous patterns. Project `CLAUDE.md` gets updated with permanent patterns.

### Review Gates
Before every commit:
- Runs `code-reviewer` agent (bugs, style, logic)
- Runs `silent-failure-hunter` agent (error handling)
- If issues found → fix → re-review → repeat
- Only commits when clean

### Story Dependencies
Stories can depend on other stories. Ralph won't start a story until all its dependencies are complete.

## When to Use Ralph

**Good for:**
- Features with clear requirements
- 8-15 independent stories
- Work that can be verified with typecheck/tests
- Features you want done while you sleep

**Not good for:**
- Exploratory work
- Major refactors without clear criteria
- Security-critical code without review
- Vague requirements

## Tips for Success

1. **Start small** - Try a 3-story feature first to learn the workflow
2. **Good passes criteria** - Be specific: "Button shows modal" not "Button works"
3. **Right-sized stories** - 15-45 minutes each, not 5 min or 2 hours
4. **Watch the first few** - Run `/ralph-next` manually for first 2-3 stories to validate the plan
5. **Review the PRD** - After `/ralph-new`, check `prd.json` before starting the loop
6. **Health checks** - Run `/ralph-doctor` if something seems off or scripts aren't working

## Troubleshooting

**Something feels broken:**
- Run `/ralph-doctor` to check project health
- It will identify and fix common issues automatically

**Ralph gets stuck on a story:**
- Check `/ralph-status` for blockers
- Review the story's passes criteria (too vague?)
- Manually fix the issue, update prd.json, continue

**Agent errors:**
- Run `/ralph-doctor` to check project health
- Ensures prd.json and progress.txt are valid

**Stories too big:**
- Edit `prd.json` manually, break into smaller stories
- Update dependencies

**Wrong order:**
- Edit `prd.json`, adjust priorities and dependencies
- Ralph picks by priority + dependencies

**Want to make changes mid-feature:**
- Edit `prd.json` directly
- Add/remove/modify stories as needed
- Ralph reads it fresh each iteration

**Old per-feature scripts found:**
- Run `/ralph-doctor` to detect and remove them
- Now using universal `.ralph/ralph.sh` script

## Story Structure Example

Each story in `prd.json`:

```json
{
  "id": "AUTH-001",
  "title": "Create auth types",
  "steps": [
    "Create types/auth.ts",
    "Add User and Session types",
    "Export from index"
  ],
  "passes": [
    "Types compile without errors",
    "Exports work correctly",
    "typecheck passes"
  ],
  "dependencies": [],
  "priority": 1,
  "status": "not_started",
  "blockers": []
}
```

## Getting Started

```
/ralph-new my-feature
→ Follow the prompts
→ Review the generated plan
→ Choose how to run it

Happy shipping!
```

## More Information

For additional details, see the Ralph skill documentation by typing `/ralph`.

## Architecture Notes

Ralph uses **agent orchestration** instead of bash scripts:
- Each story runs in a **fresh agent** with clean context
- No context bloat across stories
- Can run indefinitely without limits
- Simpler, more reliable than bash loops

**Universal script approach:**
- `.ralph/ralph.sh` - One script for all features
- `.ralph/active` - Tracks current feature name
- Script reads active feature at runtime
- No per-feature scripts needed
