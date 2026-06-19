# claude-perm

One-click permission toggle for [Claude Code](https://claude.ai/code). Suppress all tool approval prompts globally.

## Install & Use

```bash
# Run directly (no install needed)
npx github:YOUR_USERNAME/claude-perm on

# Or clone and link
git clone https://github.com/YOUR_USERNAME/claude-perm.git
cd claude-perm
npm link
claude-perm on
```

## Commands

```bash
claude-perm on       # Allow all tool calls without prompts
claude-perm off      # Restore permission prompts
claude-perm status   # Show current state
```

## What it does

Modifies `~/.claude/settings.json` to add these allow rules:

```
Bash(*), Read, Write, Edit, Glob, Grep,
Agent, WebFetch, WebSearch, NotebookEdit, Skill(*)
```

## Notes

- Changes take effect after restarting your Claude Code session
- `off` restores Claude Code's default behavior (prompts for each tool call)
- Only modifies the `permissions.allow` array — your other settings are preserved
- Works on Windows, macOS, and Linux

## License

MIT
