#!/usr/bin/env node

/**
 * Session Summarizer
 *
 * Processes Claude Code session logs and creates summaries for memory-vector.
 * Designed to run asynchronously via queue.
 */

const fs = require("fs");
const path = require("path");
const http = require("http");
const { spawn } = require("child_process");

const QUEUE_DIR = path.join(process.env.HOME, ".claude", "queue");
const LOGS_DIR = path.join(process.env.HOME, ".claude", "logs");
const SECOND_BRAIN_PATH = "/Users/asonas/workspace/memory-vector-server";

async function main() {
  // Read session data from stdin or queue file
  let sessionData;

  if (process.argv[2]) {
    // Process specific queue file
    const queueFile = process.argv[2];
    sessionData = JSON.parse(fs.readFileSync(queueFile, "utf-8"));
    // Remove processed file
    fs.unlinkSync(queueFile);
  } else {
    // Read from stdin
    let input = "";
    for await (const chunk of process.stdin) {
      input += chunk;
    }
    if (!input) {
      console.error("No session data provided");
      process.exit(1);
    }
    sessionData = JSON.parse(input);
  }

  const { sessionId, transcript, workingDirectory, timestamp } = sessionData;

  if (!transcript || transcript.length === 0) {
    console.log("Empty session, skipping");
    process.exit(0);
  }

  // Generate summary using Ollama
  const summary = await generateSummary(transcript);

  // Store in both memory-vector and graphiti (parallel)
  await Promise.all([
    storeInSecondBrain({
      sessionId,
      summary,
      workingDirectory,
      timestamp,
    }),
    storeInGraphiti({
      sessionId,
      summary,
      workingDirectory,
      timestamp,
    }),
  ]);

  console.log(`Session ${sessionId} summarized and stored (memory-vector + graphiti)`);
}

async function generateSummary(transcript) {
  // Format transcript for summarization
  const formattedTranscript = transcript
    .map((msg) => `${msg.role}: ${msg.content}`)
    .join("\n\n")
    .substring(0, 10000); // Limit to ~10k chars

  const prompt = `以下はClaude Codeとの会話ログです。この会話を簡潔に要約してください。
要約には以下を含めてください:
- 主な作業内容
- 作成/変更したファイル
- 解決した問題
- 残っている課題（あれば）

会話ログ:
${formattedTranscript}

要約:`;

  return new Promise((resolve, reject) => {
    const ollama = spawn("curl", [
      "-s",
      "http://10.0.2.90:11434/api/generate",
      "-d",
      JSON.stringify({
        model: "qwen3:32b",
        prompt: prompt,
        stream: false,
      }),
    ]);

    let output = "";
    ollama.stdout.on("data", (data) => {
      output += data.toString();
    });

    ollama.on("close", (code) => {
      if (code === 0) {
        try {
          const response = JSON.parse(output);
          resolve(response.response || "Summary generation failed");
        } catch {
          resolve("Summary generation failed: " + output.substring(0, 200));
        }
      } else {
        resolve("Summary generation failed");
      }
    });

    ollama.on("error", () => {
      resolve("Summary generation failed: Ollama not available");
    });

    // Timeout after 60 seconds
    setTimeout(() => {
      ollama.kill();
      resolve("Summary generation timed out");
    }, 60000);
  });
}

async function storeInSecondBrain({ sessionId, summary, workingDirectory, timestamp }) {
  const date = new Date(timestamp || Date.now()).toISOString().split("T")[0];
  const repoName = extractRepoName(workingDirectory);

  const content = `## セッション記録 (${date})

**作業ディレクトリ**: ${workingDirectory || "不明"}
**リポジトリ**: ${repoName || "不明"}

### サマリー

${summary}
`;

  const tags = ["session-log", date];
  if (repoName) {
    tags.push(repoName);
  }

  // sourceフィールドにリポジトリ名を含める
  const source = repoName
    ? `${repoName}/session-${sessionId}`
    : `session:${sessionId}`;

  // Store via memory-vector MCP server
  const storeScript = `
    const { storeMemory } = require('${SECOND_BRAIN_PATH}/dist/tools/store-memory.js');
    storeMemory({
      content: ${JSON.stringify(content)},
      tags: ${JSON.stringify(tags)},
      source: '${source}',
      metadata: {
        type: 'session-log',
        sessionId: '${sessionId}',
        workingDirectory: '${workingDirectory || ""}',
        project: '${repoName || ""}',
        date: '${date}'
      }
    }).then(r => console.log(r.content[0].text)).catch(console.error);
  `;

  return new Promise((resolve) => {
    const node = spawn("node", ["-e", storeScript], {
      cwd: SECOND_BRAIN_PATH,
      stdio: ["ignore", "pipe", "pipe"],
    });

    node.on("close", () => resolve());
    node.on("error", () => resolve());

    setTimeout(() => {
      node.kill();
      resolve();
    }, 30000);
  });
}

async function storeInGraphiti({ sessionId, summary, workingDirectory, timestamp }) {
  const date = new Date(timestamp || Date.now()).toISOString().split("T")[0];
  const repoName = extractRepoName(workingDirectory);

  // Graphitiにはセッションの要点をエピソードとして保存
  const content = `${date}のセッション(${repoName || workingDirectory || "不明"}): ${summary}`;

  return new Promise((resolve) => {
    const postData = JSON.stringify({
      name: `Session ${sessionId} - ${date}`,
      content: content,
      source: "session-summarizer",
      group_id: repoName || "default",
    });

    const req = http.request(
      {
        hostname: "localhost",
        port: 8003,
        path: "/episodes",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(postData),
        },
        // Graphitiはエピソード追加時にLLM埋め込みを行うため、長めのタイムアウトが必要
        timeout: 120000,
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => { data += chunk; });
        res.on("end", () => {
          console.log(`Graphiti response: ${res.statusCode} - ${data.substring(0, 100)}`);
          resolve();
        });
      }
    );

    req.on("error", () => resolve());
    req.on("timeout", () => {
      req.destroy();
      resolve();
    });

    req.write(postData);
    req.end();
  });
}

function extractRepoName(workingDirectory) {
  if (!workingDirectory) return null;

  // Extract from ghq path: /Users/asonas/ghq/github.com/owner/repo
  const ghqMatch = workingDirectory.match(/ghq\/github\.com\/([^/]+\/[^/]+)/);
  if (ghqMatch) return ghqMatch[1];

  // Extract from workspace path
  const workspaceMatch = workingDirectory.match(/workspace\/([^/]+)/);
  if (workspaceMatch) return workspaceMatch[1];

  return path.basename(workingDirectory);
}

main().catch(console.error);
