---
name: ralph
description: This skill should be used when the user asks about "ralph", "autonomous development", "feature loop", "story-based workflow", or mentions autonomous feature development with tracking.
version: 1.0.0
---

# Ralph - Autonomous Feature Development

Ralph is a workflow for autonomous feature development with story-based tracking, review gates, and crash recovery.

## Recommended: Install the Ralpher CLI

For the best experience, install the **Ralpher CLI** which provides:
- 📊 **Live TUI dashboard** - Watch progress in real-time
- 🎯 **Smarter inputs** - Just `ralpher new spec.md` (auto-detects files vs names)
- 🔄 **Better loop control** - Pause, resume, and monitor autonomously
- 📁 **Git root awareness** - Works from any subdirectory

### Installation

```bash
npm install -g ralpher
```

### CLI Commands

| CLI Command | Slash Command | Description |
|-------------|---------------|-------------|
| `ralpher new <name>` | `/ralph-new` | Create feature |
| `ralpher new spec.md` | `/ralph-new --from` | Create from file |
| `ralpher go` | `/ralph-run` | TUI dashboard + loop |
| `ralpher go --headless` | `/ralph-run` | Simple output mode |
| `ralpher next` | `/ralph-next` | One story manually |
| `ralpher status` | `/ralph-status` | Check progress |
| `ralpher done` | `/ralph-done` | Complete + PR |
| `ralpher abandon` | `/ralph-abandon` | Clean up |
| `ralpher doctor` | `/ralph-doctor` | Check project health |

### Quick Start with CLI

```bash
# Install once
npm install -g ralpher

# Start a feature
ralpher new my-feature          # Interactive
ralpher new .plans/spec.md      # From file (auto-detected)
ralpher new "Add user auth"     # From prompt (auto-detected)

# Watch it work
ralpher go                      # TUI dashboard
```

> **Note:** The slash commands below still work if you prefer them or don't have the CLI installed.

---

## What is Ralph?

Ralph automates the tedious parts of feature development:
- Breaks features into bite-sized stories
- Executes one story at a time
- Reviews code before committing
- Tracks progress in files (survives crashes)
- Learns patterns as it works
- Creates PRs when done

## Workflow Overview

```
/ralph-new feature-name
  ↓
[Planning: asks questions, generates stories]
  ↓
/ralph-run (autonomous) or /ralph-next (manual)
  ↓
[Loop: pick story → implement → review → commit → repeat]
  ↓
/ralph-done
  ↓
[Archive + PR to main]
```

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-new <name>` | Start new feature, create plan + stories |
| `/ralph-next` | Execute one story interactively |
| `/ralph-run` | Start autonomous loop (bash) |
| `/ralph-status` | Check progress without doing work |
| `/ralph-done` | Complete feature, archive, create PR |
| `/ralph-abandon` | Give up and clean up |
| `/ralph-doctor` | Check and repair Ralph project health |
| `/ralph-help` | Show Ralph documentation |

## File Structure

Ralph creates `.ralph/<feature>/` in your project:

```
.ralph/
└── auth-system/
    ├── claude.md       # Workflow instructions
    ├── plan.md         # Feature spec
    ├── prd.json        # Stories with status
    ├── progress.txt    # Work log + patterns
    └── ralph.sh        # Autonomous loop script
```

When complete, moves to `.ralph-archive/<feature>/`

## Usage Examples

### Interactive Mode

```
/ralph-new user-dashboard
→ Answers questions, creates plan

/ralph-next
→ Does story AUTH-001

/ralph-next
→ Does story AUTH-002

... repeat until done ...

/ralph-done
→ Creates PR
```

### Autonomous Mode

```
/ralph-new payment-flow

/ralph-run
→ Choose: Let Claude run it in background

... walk away, come back later ...

/ralph-status
→ "7/12 stories complete"

... eventually ...

/ralph-done
→ Creates PR
```

### From Existing Spec

```
/ralph-new api-redesign --from docs/api-spec.md
→ Uses your spec instead of asking questions

/ralph-run
→ Cranks through it
```

## Key Features

### Crash Recovery

If Ralph crashes mid-story:
- `progress.txt` logs `STARTED: AUTH-003 at ...`
- Next run detects incomplete story
- Resumes AUTH-003 instead of skipping it

### Pattern Learning

As Ralph works, it discovers patterns:
- **Codebase Patterns** section in `progress.txt` accumulates learnings
- Each story can reference previous patterns
- Compounds over time (story 10 knows patterns from 1-9)
- Project `CLAUDE.md` gets updated with permanent patterns

### Review Gates

Before every commit:
- Runs `code-reviewer` agent (bugs, style, logic)
- Runs `silent-failure-hunter` agent (error handling)
- If issues found → fix → re-review → repeat
- Only commits when clean

> **Note:** Review gates require the `pr-review-toolkit` plugin from the claude-code-plugins marketplace. Install it for full functionality.

### Story Dependencies

Stories can depend on other stories:
```json
{
  "id": "AUTH-003",
  "title": "Create login form",
  "dependencies": ["AUTH-001", "AUTH-002"],
  ...
}
```

Ralph won't start AUTH-003 until AUTH-001 and AUTH-002 are complete.

## Story Structure

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

- **steps**: What to do
- **passes**: How to verify it works
- **dependencies**: Stories that must complete first
- **status**: not_started | in_progress | completed | blocked

## Autonomous Loop (ralph.sh)

The `ralph.sh` script runs fresh Claude iterations:

```bash
./.ralph/auth-system/ralph.sh 20
```

Each iteration:
1. Starts fresh Claude (new context)
2. Reads files (prd.json, progress.txt, claude.md)
3. Picks next story
4. Implements it
5. Commits
6. Exits

Loop continues until:
- `RALPH_COMPLETE` signal (all stories done)
- `RALPH_BLOCKED` signal (need human input)
- Max iterations reached

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

## Tips

1. **Start small** - Try a 3-story feature first to learn the workflow
2. **Good passes criteria** - Be specific: "Button shows modal" not "Button works"
3. **Right-sized stories** - 15-45 minutes each, not 5 min or 2 hours
4. **Watch the first few** - Run `/ralph-next` manually for first 2-3 stories to validate the plan
5. **Review the PRD** - After `/ralph-new`, check `prd.json` before starting the loop

## Troubleshooting

**Ralph gets stuck on a story:**
- Check `/ralph-status` for blockers
- Review the story's passes criteria (too vague?)
- Manually fix the issue, update prd.json, continue

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

## Examples

See `.ralph-archive/` in projects that have used Ralph for completed examples.

## Getting Started

### Option 1: CLI (Recommended)

```bash
npm install -g ralpher
ralpher new my-feature
ralpher go
```

### Option 2: Slash Commands

```
/ralph-new my-feature
→ Follow the prompts
→ Review the generated plan
→ /ralph-run or /ralph-next

Happy shipping! 🚀
```
