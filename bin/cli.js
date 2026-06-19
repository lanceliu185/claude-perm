#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");

const SETTINGS_PATH = path.join(os.homedir(), ".claude", "settings.json");

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
];

function readSettings() {
  try {
    let raw = fs.readFileSync(SETTINGS_PATH, "utf8");
    // Strip BOM if present (PowerShell tools may write it)
    if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

function writeSettings(data) {
  const dir = path.dirname(SETTINGS_PATH);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(SETTINGS_PATH, JSON.stringify(data, null, 2) + "\n");
}

function isOn(data) {
  const allow = data.permissions?.allow || [];
  return allow.some((r) => r.includes("Bash(*)"));
}

const cmd = process.argv[2];

switch (cmd) {
  case "on": {
    const data = readSettings();
    data.permissions = data.permissions || {};
    data.permissions.allow = ALLOWED_TOOLS;
    writeSettings(data);
    console.log("✓ Permissions ON — all tool calls auto-approved");
    console.log("  Restart Claude Code session to take effect.");
    break;
  }

  case "off": {
    const data = readSettings();
    if (data.permissions) {
      delete data.permissions.allow;
      if (!Object.keys(data.permissions).length) delete data.permissions;
    }
    writeSettings(data);
    console.log("✓ Permissions OFF — tool calls will prompt for approval");
    console.log("  Restart Claude Code session to take effect.");
    break;
  }

  case "status": {
    const data = readSettings();
    if (isOn(data)) {
      console.log("Status: ON (all tools auto-approved)");
    } else {
      console.log("Status: OFF (tool calls require confirmation)");
    }
    break;
  }

  default:
    console.log(`
claude-perm — Claude Code permission toggle

Usage:
  claude-perm on       Allow all tool calls without prompts
  claude-perm off      Restore permission prompts
  claude-perm status   Show current state

Modifies: ~/.claude/settings.json
`);
}
