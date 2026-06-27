#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const os = require("os");

const SETTINGS_DIR = path.join(os.homedir(), ".claude");
const SETTINGS_PATH = path.join(SETTINGS_DIR, "settings.json");
const BACKUP_PATH = path.join(SETTINGS_DIR, "settings.backup.json");
const GUARD_PID_PATH = path.join(SETTINGS_DIR, "guard.pid");
const GUARD_LOG_PATH = path.join(SETTINGS_DIR, "guard.log");

const ALLOWED_TOOLS = [
  "*",
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
  return allow.includes("*");
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

function cleanProjectSettings(dir = process.cwd()) {
  const localSettingsPath = path.join(dir, ".claude", "settings.local.json");
  try {
    if (fs.existsSync(localSettingsPath)) {
      fs.unlinkSync(localSettingsPath);
      console.log(`✓ Removed project settings: ${localSettingsPath}`);
      return true;
    }
    console.log("No project settings found");
    return false;
  } catch (e) {
    console.error(`Clean failed: ${e.message}`);
    return false;
  }
}

function cleanAllProjectSettings() {
  const homeDir = os.homedir();
  const commonDirs = [
    path.join(homeDir, "Desktop"),
    path.join(homeDir, "Documents"),
    path.join(homeDir, "Projects"),
    path.join(homeDir, "Code"),
  ];

  let cleaned = 0;

  function scanDir(dir) {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        if (entry.isDirectory() && !entry.name.startsWith(".")) {
          const projectDir = path.join(dir, entry.name);
          const localSettingsPath = path.join(projectDir, ".claude", "settings.local.json");
          if (fs.existsSync(localSettingsPath)) {
            fs.unlinkSync(localSettingsPath);
            console.log(`✓ Removed: ${localSettingsPath}`);
            cleaned++;
          }
        }
      }
    } catch (e) {
      // Skip directories we can't read
    }
  }

  for (const dir of commonDirs) {
    if (fs.existsSync(dir)) {
      scanDir(dir);
    }
  }

  if (cleaned === 0) {
    console.log("No project settings found to clean");
  } else {
    console.log(`\n✓ Cleaned ${cleaned} project settings files`);
  }
  return cleaned;
}

function isGuardRunning() {
  try {
    if (fs.existsSync(GUARD_PID_PATH)) {
      const pid = parseInt(fs.readFileSync(GUARD_PID_PATH, "utf8").trim());
      // Check if process is running
      try {
        process.kill(pid, 0);
        return true;
      } catch {
        // Process not running, clean up pid file
        fs.unlinkSync(GUARD_PID_PATH);
        return false;
      }
    }
  } catch {}
  return false;
}

function startGuard(intervalSeconds = 30) {
  if (isGuardRunning()) {
    console.log("Guard is already running");
    return;
  }

  const pid = process.pid;
  fs.writeFileSync(GUARD_PID_PATH, pid.toString());

  console.log(`\n✓ Guard started (PID: ${pid})`);
  console.log(`  Cleaning project settings every ${intervalSeconds} seconds`);
  console.log(`  Log: ${GUARD_LOG_PATH}`);
  console.log(`  Stop: claude-perm stop-guard\n`);

  // Log function
  function log(msg) {
    const timestamp = new Date().toISOString();
    const line = `[${timestamp}] ${msg}\n`;
    fs.appendFileSync(GUARD_LOG_PATH, line);
  }

  log("Guard started");

  // Run clean immediately
  const homeDir = os.homedir();
  const commonDirs = [
    path.join(homeDir, "Desktop"),
    path.join(homeDir, "Documents"),
    path.join(homeDir, "Projects"),
    path.join(homeDir, "Code"),
  ];

  function cleanAll() {
    let cleaned = 0;
    for (const dir of commonDirs) {
      if (fs.existsSync(dir)) {
        try {
          const entries = fs.readdirSync(dir, { withFileTypes: true });
          for (const entry of entries) {
            if (entry.isDirectory() && !entry.name.startsWith(".")) {
              const projectDir = path.join(dir, entry.name);
              const localSettingsPath = path.join(projectDir, ".claude", "settings.local.json");
              if (fs.existsSync(localSettingsPath)) {
                fs.unlinkSync(localSettingsPath);
                log(`Removed: ${localSettingsPath}`);
                cleaned++;
              }
            }
          }
        } catch {}
      }
    }
    if (cleaned > 0) {
      log(`Cleaned ${cleaned} project settings files`);
    }
  }

  // Clean immediately
  cleanAll();

  // Set up interval
  setInterval(() => {
    cleanAll();
  }, intervalSeconds * 1000);

  // Keep process running
  process.on("SIGINT", () => {
    log("Guard stopped");
    if (fs.existsSync(GUARD_PID_PATH)) {
      fs.unlinkSync(GUARD_PID_PATH);
    }
    process.exit(0);
  });

  process.on("SIGTERM", () => {
    log("Guard stopped");
    if (fs.existsSync(GUARD_PID_PATH)) {
      fs.unlinkSync(GUARD_PID_PATH);
    }
    process.exit(0);
  });
}

function stopGuard() {
  if (!isGuardRunning()) {
    console.log("Guard is not running");
    return;
  }

  try {
    const pid = parseInt(fs.readFileSync(GUARD_PID_PATH, "utf8").trim());
    process.kill(pid, "SIGTERM");
    fs.unlinkSync(GUARD_PID_PATH);
    console.log(`✓ Guard stopped (PID: ${pid})`);
  } catch (e) {
    console.log(`Guard stopped`);
    if (fs.existsSync(GUARD_PID_PATH)) {
      fs.unlinkSync(GUARD_PID_PATH);
    }
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
    console.log("  Cleaning project-level settings...");
    cleanProjectSettings();
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

  case "clean": {
    cleanProjectSettings();
    break;
  }

  case "clean-all": {
    cleanAllProjectSettings();
    break;
  }

  case "guard": {
    const interval = parseInt(process.argv[3]) || 30;
    startGuard(interval);
    break;
  }

  case "stop-guard": {
    stopGuard();
    break;
  }

  case "guard-status": {
    if (isGuardRunning()) {
      const pid = fs.readFileSync(GUARD_PID_PATH, "utf8").trim();
      console.log(`Guard is running (PID: ${pid})`);
    } else {
      console.log("Guard is not running");
    }
    break;
  }

  case "more": {
    showStatus();
    console.log("  Commands:");
    console.log(`  ${"─".repeat(50)}`);
    console.log("    claude-perm on          Allow all tool calls");
    console.log("    claude-perm off         Restore permission prompts");
    console.log("    claude-perm status      Show current state");
    console.log("    claude-perm backup      Backup current settings");
    console.log("    claude-perm restore     Restore from backup");
    console.log("    claude-perm clean       Remove project settings");
    console.log("    claude-perm clean-all   Remove all project settings");
    console.log("    claude-perm guard       Start guard (auto-clean)");
    console.log("    claude-perm stop-guard  Stop guard");
    console.log("    claude-perm guard-status Check guard status");
    console.log("    claude-perm more        Show this help");
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
    claude-perm on          Allow all tool calls without prompts
    claude-perm off         Restore permission prompts
    claude-perm status      Show current state
    claude-perm backup      Backup current settings
    claude-perm restore     Restore settings from backup
    claude-perm clean       Remove project-level settings
    claude-perm clean-all   Remove all project settings
    claude-perm guard       Start guard (auto-clean every 30s)
    claude-perm stop-guard  Stop guard
    claude-perm guard-status Check guard status
    claude-perm more        Show detailed info

  Settings: ~/.claude/settings.json
  Backup:   ~/.claude/settings.backup.json

  Examples:
    claude-perm on          # Enable permissions
    claude-perm guard       # Start auto-clean guard
    claude-perm clean-all   # Clean all project settings
    claude-perm status      # Check current state
`);
  }
}
