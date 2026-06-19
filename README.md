# claude-perm

> One-click permission toggle for [Claude Code](https://docs.anthropic.com/en/docs/claude-code)

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D16-brightgreen.svg)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)]()

Tired of Claude Code asking for permission every time it runs a command? `claude-perm` lets you toggle all tool permissions on/off with a single click or command.

## Quick Start

```bash
# One-liner (no install)
npx github:lanceliu185/claude-perm on

# That's it. Restart Claude Code and enjoy.
```

## Installation

```bash
# Option 1: npx (recommended — no install needed)
npx github:lanceliu185/claude-perm on

# Option 2: Clone and link globally
git clone https://github.com/lanceliu185/claude-perm.git
cd claude-perm
npm link

# Option 3: Download the .exe (Windows only)
# Grab claude-perm.exe from Releases
```

## Usage

### CLI (all platforms)

```bash
claude-perm on       # Allow all tool calls without prompts
claude-perm off      # Restore permission prompts
claude-perm status   # Show current state
```

### GUI (Windows)

Double-click `claude-perm.exe` for a visual toggle switch.

Dark-themed interface with:
- Clickable toggle switch
- ON / OFF buttons
- Live status display
- Tool list preview

To build the `.exe` yourself:

```powershell
Install-Module ps2exe -Scope CurrentUser
npm run build:exe
```

## What It Does

Modifies `~/.claude/settings.json` to add allow rules:

```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read",
      "Write",
      "Edit",
      "Glob",
      "Grep",
      "Agent",
      "WebFetch",
      "WebSearch",
      "NotebookEdit",
      "Skill(*)"
    ]
  }
}
```

When turned off, the `permissions.allow` array is removed, restoring default behavior.

## Allowed Tools

| Tool | What It Covers |
|------|---------------|
| `Bash(*)` | All shell commands |
| `Read` | Read any file |
| `Write` | Write any file |
| `Edit` | Edit any file |
| `Glob` | File pattern matching |
| `Grep` | Content search |
| `Agent` | Sub-agent spawning |
| `WebFetch` | URL fetching |
| `WebSearch` | Web search |
| `NotebookEdit` | Jupyter notebooks |
| `Skill(*)` | All skills |

## Project Structure

```
claude-perm/
├── bin/
│   └── cli.js           # Node.js CLI (zero dependencies)
├── src/
│   └── claude-perm.ps1  # PowerShell WPF GUI source
├── package.json
├── LICENSE              # MIT
└── README.md
```

## How It Works

1. Reads `~/.claude/settings.json`
2. Adds/removes the `permissions.allow` array
3. Writes the file back (UTF-8 without BOM)
4. On next Claude Code restart, the new permissions take effect

Other settings in your `settings.json` (env vars, model config, etc.) are preserved.

## Requirements

| Component | Requirement |
|-----------|------------|
| CLI | Node.js >= 16 |
| GUI (.exe) | Windows 10+, PowerShell 5.1+ |
| Claude Code | Any version |

## FAQ

**Q: Do I need to restart Claude Code after toggling?**
A: Yes. Claude Code reads settings at startup. Restart the session for changes to take effect.

**Q: Is this safe?**
A: It only modifies the `permissions` section of your settings file. Your API keys, model config, and other settings are untouched.

**Q: Does it work with VS Code / JetBrains extensions?**
A: Yes. It modifies the same `~/.claude/settings.json` used by all Claude Code interfaces.

**Q: Can I customize which tools are allowed?**
A: Edit the `ALLOWED_TOOLS` array in `bin/cli.js` or `src/claude-perm.ps1`.

## License

[MIT](LICENSE)
