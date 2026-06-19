# claude-perm

One-click permission toggle for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

Suppress all tool approval prompts (Bash, Read, Write, Edit, Web, etc.) with a single click or command.

## Installation

```bash
# Run directly via npx (no install)
npx github:YOUR_USERNAME/claude-perm on

# Or clone and link
git clone https://github.com/YOUR_USERNAME/claude-perm.git
cd claude-perm
npm link
```

## Usage

### CLI

```bash
claude-perm on       # Allow all tool calls without prompts
claude-perm off      # Restore permission prompts
claude-perm status   # Show current state
```

### GUI (Windows only)

Double-click `src/claude-perm.ps1` or build the `.exe`:

```powershell
# Requires ps2exe module
Install-Module ps2exe -Scope CurrentUser
Import-Module ps2exe
Invoke-PS2EXE -InputFile src/claude-perm.ps1 -OutputFile claude-perm.exe -noConsole -title "Claude Code Permission Toggle"
```

Then double-click `claude-perm.exe` to toggle permissions with a visual switch.

## What it does

Modifies `~/.claude/settings.json` to add these allow rules:

```
Bash(*), Read, Write, Edit, Glob, Grep,
Agent, WebFetch, WebSearch, NotebookEdit, Skill(*)
```

When `off`, the `permissions.allow` array is removed, restoring Claude Code's default behavior.

## Allowed Tools

| Tool | Description |
|------|-------------|
| `Bash(*)` | All shell commands |
| `Read` | File reading |
| `Write` | File writing |
| `Edit` | File editing |
| `Glob` | File pattern search |
| `Grep` | Content search |
| `Agent` | Sub-agents |
| `WebFetch` | URL fetching |
| `WebSearch` | Web search |
| `NotebookEdit` | Jupyter notebooks |
| `Skill(*)` | All skills |

## Notes

- Restart your Claude Code session after toggling for changes to take effect
- Only modifies `permissions.allow` — your other settings (env, model, etc.) are preserved
- Works on Windows, macOS, and Linux (CLI version)
- GUI requires Windows 10+ with PowerShell 5.1+

## License

MIT
