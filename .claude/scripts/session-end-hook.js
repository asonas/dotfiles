#!/usr/bin/env node

/**
 * Session End Hook
 *
 * Called when a Claude Code session ends.
 * Queues the session for async summarization.
 */

const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const QUEUE_DIR = path.join(process.env.HOME, ".claude", "queue");
const SCRIPTS_DIR = path.join(process.env.HOME, ".claude", "scripts");

async function main() {
  // Read hook input from stdin
  let input = "";
  for await (const chunk of process.stdin) {
    input += chunk;
  }

  let hookData;
  try {
    hookData = JSON.parse(input);
  } catch {
    // Not JSON input, exit silently
    process.exit(0);
  }

  // Extract session information
  const sessionId = hookData.session_id || `session-${Date.now()}`;
  const transcript = hookData.transcript || hookData.messages || [];
  const workingDirectory = hookData.cwd || hookData.working_directory || process.cwd();

  // Skip empty sessions
  if (!transcript || transcript.length < 2) {
    process.exit(0);
  }

  // Create queue file for async processing
  const queueFile = path.join(QUEUE_DIR, `${sessionId}.json`);
  const queueData = {
    sessionId,
    transcript,
    workingDirectory,
    timestamp: new Date().toISOString(),
  };

  fs.mkdirSync(QUEUE_DIR, { recursive: true });
  fs.writeFileSync(queueFile, JSON.stringify(queueData, null, 2));

  // Spawn background process to handle summarization
  const summarizer = spawn(
    "node",
    [path.join(SCRIPTS_DIR, "session-summarizer.js"), queueFile],
    {
      detached: true,
      stdio: "ignore",
    }
  );

  // Detach the child process so it runs independently
  summarizer.unref();

  // Return immediately (hook completes, summarizer runs in background)
  console.log(JSON.stringify({ status: "queued", sessionId }));
}

main().catch(() => process.exit(0));
