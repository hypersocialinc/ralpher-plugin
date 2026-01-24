# Ralph Agents

> ⚠️ **This folder is managed by [Ralpher](https://ralpher.dev)**
>
> Files in this folder are automatically installed and updated by the Ralpher desktop app.
> Manual edits may be overwritten when Ralpher updates.

## Agents

| Agent | Description |
|-------|-------------|
| `ralph-planner` | Gathers requirements and creates feature plan with stories |
| `ralph-worker` | Executes one story with quality gates (typecheck, review, tests) |
| `ralph-dispatcher` | Analyzes stories and selects batch for parallel execution |

## Agent Flow

```
/ralph-new → ralph-planner
    ↓
    Creates plan.md + prd.json
    ↓
/ralph-go → ralph-dispatcher (parallel mode)
    ↓
    Returns batch of ready stories
    ↓
ralph-worker × N (parallel)
    ↓
    Each worker: implement → typecheck → review → test → commit
    ↓
Repeat until RALPH_COMPLETE
```

## How This Works

1. Ralpher desktop app bundles these agents from [ralpher-plugin](https://github.com/hypersocialinc/ralpher-plugin)
2. When you open a project, Ralpher installs/updates agents to `.claude/agents/`
3. Claude Code discovers agents and makes them available as subagents

## Agent Capabilities

**ralph-planner** (`opus` model)
- Interactive requirements gathering via AskUserQuestion
- Codebase exploration (Glob, Grep, Read)
- Story dependency analysis
- Creates 8-15 properly-sized stories

**ralph-worker** (`opus` model)
- Implements one story per invocation
- Loads skill contexts (convex, clerk, baml)
- Spawns design agents for frontend stories
- Mandatory review gates before commit
- Crash recovery via progress.txt logging

**ralph-dispatcher** (`haiku` model)
- Fast, lightweight batch selection
- Reads prd.json to find ready stories
- Respects dependencies and priorities
- Returns JSON array of story IDs

## Source Repository

These agents are maintained at: https://github.com/hypersocialinc/ralpher-plugin
