# claude-perm

> 一键切换 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 权限模式
>
> One-click permission toggle for Claude Code

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Node.js](https://img.shields.io/badge/Node.js-%3E%3D16-brightgreen.svg)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)]()

---

[English](#english) | 中文

---

## 中文

### 这是什么？

每次让 Claude Code 跑命令都要点确认？太烦了。

`claude-perm` 可以一键关闭所有权限确认弹窗，让 Claude Code 畅通无阻地执行 Bash、文件读写、网页抓取等所有工具调用。

### 快速开始

**第一步：确保 Claude Code 已经完全关闭**（退出终端中的 claude 会话，或直接关闭窗口）

**第二步：运行命令**

```bash
# 一行命令搞定（无需安装）
npx github:lanceliu185/claude-perm on
```

**第三步：重新打开 Claude Code**，权限已生效，不再弹确认框。

### 安装方式

```bash
# 方式 1：npx 直接运行（推荐，无需安装）
npx github:lanceliu185/claude-perm on

# 方式 2：克隆并全局安装
git clone https://github.com/lanceliu185/claude-perm.git
cd claude-perm
npm link

# 方式 3：下载 exe（仅 Windows）
# 从 Releases 页面下载 claude-perm.exe，双击即用
```

### 使用方法

#### 命令行（全平台）

```bash
claude-perm on       # 开启权限，所有工具自动放行
claude-perm off      # 关闭权限，恢复逐个确认
claude-perm status   # 查看当前状态
```

#### 图形界面（Windows）

双击 `claude-perm.exe`，弹出深色主题窗口：

- 点击圆形开关切换 ON / OFF
- 或点击底部按钮切换
- 实时显示当前状态
- 底部列出已授权工具列表

自行编译 exe：

```powershell
Install-Module ps2exe -Scope CurrentUser
npm run build:exe
```

### 开了哪些权限？

修改 `~/.claude/settings.json`，添加以下放行规则：

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

关闭时会移除 `permissions.allow`，恢复 Claude Code 默认行为。

### 放行的工具一览

| 工具 | 说明 |
|------|------|
| `Bash(*)` | 所有 Shell 命令 |
| `Read` | 读取文件 |
| `Write` | 写入文件 |
| `Edit` | 编辑文件 |
| `Glob` | 文件名匹配搜索 |
| `Grep` | 文件内容搜索 |
| `Agent` | 子代理 |
| `WebFetch` | 网页抓取 |
| `WebSearch` | 网页搜索 |
| `NotebookEdit` | Jupyter 笔记本 |
| `Skill(*)` | 所有 Skills |

### 项目结构

```
claude-perm/
├── bin/
│   └── cli.js           # Node.js 命令行（零依赖）
├── src/
│   └── claude-perm.ps1  # PowerShell WPF 图形界面源码
├── package.json
├── LICENSE              # MIT
└── README.md
```

### 工作原理

1. 读取 `~/.claude/settings.json`
2. 添加或移除 `permissions.allow` 数组
3. 写回文件（UTF-8 无 BOM）
4. 重启 Claude Code 后生效

你原有的其他设置（环境变量、模型配置等）完全不受影响。

### 系统要求

| 组件 | 要求 |
|------|------|
| 命令行 | Node.js >= 16 |
| 图形界面 (exe) | Windows 10+，PowerShell 5.1+ |
| Claude Code | 任意版本 |

### 常见问题

**Q：切换后需要重启 Claude Code 吗？**
A：是的。Claude Code 在启动时读取设置，重启会话后才生效。

**Q：安全吗？**
A：只修改 `permissions` 部分，你的 API Key、模型配置等其他设置不受影响。

**Q：VS Code / JetBrains 插件也能用吗？**
A：能。它修改的是所有 Claude Code 界面共用的 `~/.claude/settings.json`。

**Q：想自定义允许哪些工具？**
A：编辑 `bin/cli.js` 或 `src/claude-perm.ps1` 里的 `ALLOWED_TOOLS` 数组即可。

---

<a id="english"></a>

## English

### What is it?

Tired of Claude Code asking for permission every time it runs a command? `claude-perm` lets you toggle all tool permissions on/off with a single click or command.

### Quick Start

**Step 1: Make sure Claude Code is fully closed** (exit the claude session in your terminal, or close the window)

**Step 2: Run the command**

```bash
# One-liner (no install)
npx github:lanceliu185/claude-perm on
```

**Step 3: Reopen Claude Code** — permissions are now active, no more approval prompts.

### Installation

```bash
# Option 1: npx (recommended)
npx github:lanceliu185/claude-perm on

# Option 2: Clone and link globally
git clone https://github.com/lanceliu185/claude-perm.git
cd claude-perm
npm link

# Option 3: Download the .exe (Windows only)
# Grab claude-perm.exe from Releases
```

### Usage

#### CLI (all platforms)

```bash
claude-perm on       # Allow all tool calls without prompts
claude-perm off      # Restore permission prompts
claude-perm status   # Show current state
```

#### GUI (Windows)

Double-click `claude-perm.exe` for a visual toggle switch.

- Clickable toggle switch
- ON / OFF buttons
- Live status display
- Tool list preview

### What It Does

Modifies `~/.claude/settings.json` to add allow rules:

```json
{
  "permissions": {
    "allow": [
      "Bash(*)", "Read", "Write", "Edit", "Glob", "Grep",
      "Agent", "WebFetch", "WebSearch", "NotebookEdit", "Skill(*)"
    ]
  }
}
```

### Allowed Tools

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

### FAQ

**Q: Do I need to restart Claude Code after toggling?**
A: Yes. Claude Code reads settings at startup. Restart the session for changes to take effect.

**Q: Is this safe?**
A: It only modifies the `permissions` section. Your API keys, model config, and other settings are untouched.

**Q: Does it work with VS Code / JetBrains extensions?**
A: Yes. It modifies the same `~/.claude/settings.json` used by all Claude Code interfaces.

**Q: Can I customize which tools are allowed?**
A: Edit the `ALLOWED_TOOLS` array in `bin/cli.js` or `src/claude-perm.ps1`.

## License

[MIT](LICENSE)
