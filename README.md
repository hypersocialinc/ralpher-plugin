# Ralph - Autonomous Feature Development for Claude Code

A Claude Code plugin that implements [Ralph loops](https://ghuntley.com/ralph/) for autonomous feature development with story-based tracking, review gates, and crash recovery.

## What is a Ralph Loop?

Ralph loops solve "context rot" in AI coding sessions. Instead of one long conversation where the AI gradually loses context:

1. **Fresh context each iteration** - No accumulated confusion
2. **File-based memory** - PRD, progress logs, and patterns persist between runs
3. **One story at a time** - Focused, completable units of work
4. **Automatic crash recovery** - Pick up exactly where you left off

This approach is validated by [Anthropic's research](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) on long-running agents.

## Installation

```bash
claude plugin add hypersocialinc/ralpher-plugin
```

Or install the recommended plugin bundle:
```bash
claude plugin add hypersocialinc/ralpher-plugin
claude plugin add hypersocialinc/pr-review-toolkit  # For review gates
```

## Quick Start

```bash
# 1. Start a new feature
/ralph-new auth-feature

# 2. Ralph asks questions and generates stories
# ...answers questions...

# 3. Run autonomously
/ralph-run

# 4. Check progress anytime
/ralph-status

# 5. When complete, create PR
/ralph-done
```

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-new <name>` | Start a new feature - creates branch, generates stories |
| `/ralph-run` | Run autonomous loop (executes stories until complete) |
| `/ralph-next` | Execute just one story (manual mode) |
| `/ralph-status` | Show current progress |
| `/ralph-done` | Archive feature and create PR |
| `/ralph-abandon` | Cancel feature and clean up |
| `/ralph-doctor` | Check and repair Ralph state |
| `/ralph-help` | Show documentation |

## How It Works

### 1. Planning Phase (`/ralph-new`)

Ralph asks 3-5 clarifying questions about your feature, then generates:

- **plan.md** - Feature specification
- **prd.json** - Stories with acceptance criteria, dependencies, priorities

### 2. Execution Phase (`/ralph-run`)

For each story, Ralph:

1. Reads current state from files
2. Implements the story
3. Runs typecheck (with retry loop)
4. Runs review agents (code-reviewer, silent-failure-hunter)
5. Commits with conventional format
6. Updates progress log
7. Exits cleanly for fresh context

### 3. Completion Phase (`/ralph-done`)

- Verifies all stories complete
- Archives `.ralph/<feature>/` to `.ralph-archive/`
- Creates PR with summary

## File Structure

```
your-project/
├── .ralph/
│   └── auth-feature/
│       ├── plan.md        # Feature specification
│       ├── prd.json       # Stories with status
│       ├── progress.txt   # Work log + learned patterns
│       └── ralph-go.sh    # Bash loop script
└── .ralph-archive/        # Completed features
```

## Story Schema

```json
{
  "id": "AUTH-001",
  "title": "Add login form",
  "type": "frontend",
  "skills": ["clerk"],
  "steps": ["Create component", "Add validation"],
  "passes": ["Form renders", "Validation works", "Tests pass"],
  "dependencies": [],
  "priority": 1,
  "status": "not_started"
}
```

## Pattern Learning

Ralph accumulates knowledge in `progress.txt`:

```markdown
## Codebase Patterns
- Always use IF NOT EXISTS in migrations
- Run dev server before E2E tests
- Export types from actions.ts
```

These patterns compound across stories, improving quality over time.

## Requirements

- Claude Code CLI
- Git
- Recommended: [pr-review-toolkit](https://github.com/hypersocialinc/pr-review-toolkit) plugin for review gates

## Integration with Ralpher App

This plugin works standalone, but pairs with [Ralpher](https://ralpher.dev) for:

- Visual dashboard with story progress
- Multi-project management
- Team collaboration features

## Credits

- Ralph loop technique by [Geoffrey Huntley](https://ghuntley.com/ralph/)
- Built by [HyperSocial](https://github.com/hypersocialinc)

## License

MIT
