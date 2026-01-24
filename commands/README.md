# Ralph Commands

> ⚠️ **This folder is managed by [Ralpher](https://ralpher.dev)**
>
> Files in this folder are automatically installed and updated by the Ralpher desktop app.
> Manual edits may be overwritten when Ralpher updates.

## Commands

| Command | Description |
|---------|-------------|
| `/ralph-new` | Create a new feature with stories |
| `/ralph-go` | Start autonomous execution loop |
| `/ralph-run` | Alias for /ralph-go |
| `/ralph-next` | Execute one story (manual mode) |
| `/ralph-status` | Show feature progress |
| `/ralph-done` | Complete feature and create PR |
| `/ralph-abandon` | Delete feature and clean up |
| `/ralph-doctor` | Diagnose and fix issues |
| `/ralph-help` | Show help information |
| `/ralph-review-plan` | Review and refine plan |

## How This Works

1. Ralpher desktop app bundles these commands from [ralpher-plugin](https://github.com/hypersocialinc/ralpher-plugin)
2. When you open a project, Ralpher installs/updates commands to `.claude/commands/`
3. Claude Code automatically discovers these commands via slash commands

## Updating Commands

Commands are updated automatically when:
- You open a project in Ralpher desktop app
- The bundled plugin version is newer than installed

To force update: Open the project in Ralpher and it will sync the latest version.

## Source Repository

These commands are maintained at: https://github.com/hypersocialinc/ralpher-plugin
