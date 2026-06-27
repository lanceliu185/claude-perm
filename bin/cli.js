#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");

const SETTINGS_DIR = path.join(os.homedir(), ".claude");
const SETTINGS_PATH = path.join(SETTINGS_DIR, "settings.json");
const BACKUP_PATH = path.join(SETTINGS_DIR, "settings.backup.json");

const ALLOWED_TOOLS = [
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
  "Skill(*)",
  "TaskCreate",
  "TaskUpdate",
  "TaskList",
  "TaskGet",
  "TaskOutput",
  "TaskStop",
  "CronCreate",
  "CronDelete",
  "CronList",
  "ScheduleWakeup",
  "SendMessage",
  "DesignSync",
  "Workflow",
];

const TOOL_DESCRIPTIONS = {
  "Bash(*)": "Execute shell commands",
  "Read": "Read file contents",
  "Write": "Write/create files",
  "Edit": "Edit existing files",
  "Glob": "Search files by pattern",
  "Grep": "Search file contents",
  "Agent": "Spawn sub-agents",
  WebFetch: "Fetch web content",
  WebSearch: "Search the web",
  NotebookEdit: "Edit Jupyter notebooks",
  "Skill(*)": "Execute all skills",
  TaskCreate: "Create task lists",
  TaskUpdate: "Update task status",
  TaskList: "List all tasks",
  TaskGet: "Get task details",
  TaskOutput: "Get task output",
  TaskStop: "Stop running tasks",
  CronCreate: "Create scheduled tasks",
  CronDelete: "Delete scheduled tasks",
  CronList: "List scheduled tasks",
  ScheduleWakeup: "Schedule wakeups",
  SendMessage: "Send messages to agents",
  DesignSync: "Sync design systems",
  Workflow: "Execute workflows",
};

function readSettings() {
  try {
    if (!fs.existsSync(SETTINGS_PATH)) return {};
    let raw = fs.readFileSync(SETTINGS_PATH, "utf8");
    // Strip BOM if present
    if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);
    return JSON.parse(raw);
  } catch (e) {
    console.error(`Error reading settings: ${e.message}`);
    return {};
  }
}

function writeSettings(data) {
  try {
    if (!fs.existsSync(SETTINGS_DIR)) fs.mkdirSync(SETTINGS_DIR, { recursive: true });
    fs.writeFileSync(SETTINGS_PATH, JSON.stringify(data, null, 2) + "\n", "utf8");
  } catch (e) {
    console.error(`Error writing settings: ${e.message}`);
    process.exit(1);
  }
}

function isOn(data) {
  const allow = data.permissions?.allow || [];
  return allow.some((r) => r.includes("Bash(*)"));
}

function backupSettings() {
  try {
    if (fs.existsSync(SETTINGS_PATH)) {
      fs.copyFileSync(SETTINGS_PATH, BACKUP_PATH);
      console.log("✓ Settings backed up");
      return true;
    }
    console.log("No settings file to backup");
    return false;
  } catch (e) {
    console.error(`Backup failed: ${e.message}`);
    return false;
  }
}

function restoreSettings() {
  try {
    if (fs.existsSync(BACKUP_PATH)) {
      fs.copyFileSync(BACKUP_PATH, SETTINGS_PATH);
      console.log("✓ Settings restored from backup");
      return true;
    }
    console.log("No backup file found");
    return false;
  } catch (e) {
    console.error(`Restore failed: ${e.message}`);
    return false;
  }
}

function showStatus() {
  const data = readSettings();
  const enabled = isOn(data);

  console.log(`\n╔════════════════════════════════════════════════════════════╗`);
  console.log(`║           claude-perm — Permission Status                 ║`);
  console.log(`╚════════════════════════════════════════════════════════════╝\n`);

  if (enabled) {
    console.log(`  Status:  ✓ ON (all tools auto-approved)\n`);
  } else {
    console.log(`  Status:  ✗ OFF (tool calls require confirmation)\n`);
  }

  console.log(`  Settings:  ${SETTINGS_PATH}`);
  if (fs.existsSync(BACKUP_PATH)) {
    console.log(`  Backup:    ${BACKUP_PATH}`);
  }
  console.log();

  if (enabled) {
    console.log(`  Allowed Tools:`);
    console.log(`  ${"─".repeat(50)}`);
    const allow = data.permissions?.allow || [];
    allow.forEach((tool) => {
      const desc = TOOL_DESCRIPTIONS[tool] || "";
      console.log(`    • ${tool.padEnd(16)} ${desc}`);
    });
  }
  console.log();
}

const cmd = process.argv[2];

switch (cmd) {
  case "on": {
    const data = readSettings();
    backupSettings();
    data.permissions = data.permissions || {};
    data.permissions.allow = ALLOWED_TOOLS;
    writeSettings(data);
    console.log("\n✓ Permissions ON — all tool calls auto-approved");
    console.log("  Restart Claude Code session to take effect.\n");
    break;
  }

  case "off": {
    const data = readSettings();
    if (data.permissions) {
      delete data.permissions.allow;
      if (!Object.keys(data.permissions).length) delete data.permissions;
    }
    writeSettings(data);
    console.log("\n✓ Permissions OFF — tool calls will prompt for approval");
    console.log("  Restart Claude Code session to take effect.\n");
    break;
  }

  case "status": {
    showStatus();
    break;
  }

  case "backup": {
    backupSettings();
    break;
  }

  case "restore": {
    restoreSettings();
    break;
  }

  case "more": {
    showStatus();
    console.log("  Commands:");
    console.log(`  ${"─".repeat(50)}`);
    console.log("    claude-perm on       Allow all tool calls");
    console.log("    claude-perm off      Restore permission prompts");
    console.log("    claude-perm status   Show current state");
    console.log("    claude-perm backup   Backup current settings");
    console.log("    claude-perm restore  Restore from backup");
    console.log("    claude-perm more     Show this help");
    console.log();
    break;
  }

  default: {
    console.log(`
╔════════════════════════════════════════════════════════════╗
║           claude-perm — Permission Toggle                  ║
╚════════════════════════════════════════════════════════════╝

  One-click toggle for Claude Code permissions

  Usage:
    claude-perm on       Allow all tool calls without prompts
    claude-perm off      Restore permission prompts
    claude-perm status   Show current state
    claude-perm backup   Backup current settings
    claude-perm restore  Restore settings from backup
    claude-perm more     Show detailed info

  Settings: ~/.claude/settings.json
  Backup:   ~/.claude/settings.backup.json

  Examples:
    claude-perm on       # Enable permissions
    claude-perm off      # Disable permissions
    claude-perm backup   # Backup before changes
    claude-perm status   # Check current state
`);
  }
}
