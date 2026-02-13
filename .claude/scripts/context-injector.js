#!/usr/bin/env node

/**
 * Context Injector for Claude Code
 *
 * This hook script automatically injects relevant context from:
 * - memory-vector (PostgreSQL + pgvector): セマンティック検索
 * - memory-graph (Neo4j): ファクト/関係性の検索
 */

const { spawn } = require("child_process");
const path = require("path");
const http = require("http");

// Intent keywords mapping
const INTENT_KEYWORDS = {
  debug: [
    "バグ",
    "エラー",
    "bug",
    "error",
    "デバッグ",
    "debug",
    "修正",
    "fix",
    "問題",
    "issue",
    "動かない",
    "失敗",
    "fail",
  ],
  design: [
    "設計",
    "design",
    "アーキテクチャ",
    "architecture",
    "構成",
    "structure",
    "どう実装",
    "how to implement",
  ],
  investigation: [
    "調査",
    "investigate",
    "調べ",
    "search",
    "確認",
    "check",
    "なぜ",
    "why",
    "原因",
    "cause",
  ],
  refactor: [
    "リファクタ",
    "refactor",
    "改善",
    "improve",
    "整理",
    "clean",
    "最適化",
    "optimize",
  ],
};

// Minimum similarity threshold for injecting context (memory-vector)
const SIMILARITY_THRESHOLD = 0.35;

// Maximum contexts to inject from each source
const MAX_CONTEXTS = 2;

// Graphiti server URL
const GRAPHITI_URL = "http://localhost:8003";

// Minimum prompt length to trigger search (even without intent keywords)
const MIN_PROMPT_LENGTH_FOR_SEARCH = 15;

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

  const userPrompt = hookData.prompt || hookData.user_prompt || "";
  if (!userPrompt || userPrompt.length < 5) {
    process.exit(0);
  }

  // Extract repository name from working directory
  const workingDirectory = hookData.cwd || hookData.working_directory || "";
  const repoName = extractRepoName(workingDirectory);

  // Detect intent from keywords
  const detectedIntents = detectIntent(userPrompt);

  // Search if intent detected OR prompt is long enough (general context lookup)
  const shouldSearch =
    detectedIntents.length > 0 || userPrompt.length >= MIN_PROMPT_LENGTH_FOR_SEARCH;

  if (!shouldSearch) {
    process.exit(0);
  }

  // Build search query: include repo name for better relevance
  const searchQuery = repoName ? `${repoName} ${userPrompt}` : userPrompt;

  // Search both sources in parallel
  try {
    const [secondBrainResults, graphitiResults] = await Promise.all([
      searchSecondBrain(searchQuery),
      searchGraphiti(searchQuery, repoName),
    ]);

    if (secondBrainResults.length > 0 || graphitiResults.length > 0) {
      // Output context injection message
      const contextMessage = formatContextInjection(
        secondBrainResults,
        graphitiResults,
        detectedIntents,
        repoName
      );
      console.log(
        JSON.stringify({
          message: contextMessage,
        })
      );
    }
  } catch {
    // Silently fail - don't block the user
    process.exit(0);
  }
}

function extractRepoName(workingDirectory) {
  if (!workingDirectory) return null;

  // Extract from ghq path: /Users/asonas/ghq/github.com/owner/repo
  const ghqMatch = workingDirectory.match(/ghq\/github\.com\/[^/]+\/([^/]+)/);
  if (ghqMatch) return ghqMatch[1];

  // Extract from workspace path
  const workspaceMatch = workingDirectory.match(/workspace\/([^/]+)/);
  if (workspaceMatch) return workspaceMatch[1];

  return null;
}

function detectIntent(prompt) {
  const lowerPrompt = prompt.toLowerCase();
  const detected = [];

  for (const [intent, keywords] of Object.entries(INTENT_KEYWORDS)) {
    for (const keyword of keywords) {
      if (lowerPrompt.includes(keyword.toLowerCase())) {
        detected.push(intent);
        break;
      }
    }
  }

  return detected;
}

async function searchSecondBrain(query) {
  return new Promise((resolve) => {
    const scriptPath = path.join(
      "/Users/asonas/workspace/second-brain-server",
      "dist",
      "tools",
      "search-memory.js"
    );

    const searchScript = `
      const { searchMemory } = require('${scriptPath}');
      searchMemory({ query: ${JSON.stringify(query)}, limit: ${MAX_CONTEXTS} })
        .then(r => {
          const data = JSON.parse(r.content[0].text);
          console.log(JSON.stringify(data.results || []));
          process.exit(0);
        })
        .catch(() => {
          console.log('[]');
          process.exit(0);
        });
    `;

    const child = spawn("node", ["-e", searchScript], {
      cwd: "/Users/asonas/workspace/second-brain-server",
      timeout: 5000,
    });

    let output = "";
    child.stdout.on("data", (data) => {
      output += data;
    });

    child.on("close", () => {
      try {
        const results = JSON.parse(output);
        const filtered = results.filter(
          (r) => r.similarity >= SIMILARITY_THRESHOLD
        );
        resolve(filtered);
      } catch {
        resolve([]);
      }
    });

    child.on("error", () => resolve([]));

    // Timeout fallback
    setTimeout(() => resolve([]), 5000);
  });
}

async function searchGraphiti(query, groupId = null) {
  return new Promise((resolve) => {
    const requestBody = {
      query: query,
      num_results: MAX_CONTEXTS,
    };
    // If groupId (repo name) is provided, search within that group
    if (groupId) {
      requestBody.group_ids = [groupId];
    }
    const postData = JSON.stringify(requestBody);

    const options = {
      hostname: "localhost",
      port: 8003,
      path: "/search",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
      },
      timeout: 5000,
    };

    const req = http.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        try {
          const result = JSON.parse(data);
          // Graphiti returns facts as an array
          if (result.facts && Array.isArray(result.facts)) {
            resolve(result.facts);
          } else {
            resolve([]);
          }
        } catch {
          resolve([]);
        }
      });
    });

    req.on("error", () => resolve([]));
    req.on("timeout", () => {
      req.destroy();
      resolve([]);
    });

    req.write(postData);
    req.end();
  });
}

function formatContextInjection(secondBrainResults, graphitiResults, intents, repoName = null) {
  const intentLabels = {
    debug: "デバッグ",
    design: "設計",
    investigation: "調査",
    refactor: "リファクタリング",
  };

  // Build header with intents and repo name
  let headerParts = [];
  if (intents.length > 0) {
    const intentStr = intents.map((i) => intentLabels[i] || i).join(", ");
    headerParts.push(intentStr);
  }
  if (repoName) {
    headerParts.push(repoName);
  }
  const headerLabel = headerParts.length > 0 ? headerParts.join(" / ") : "コンテキスト";

  let message = `\n---\n**[Memory: ${headerLabel}]**\n\n`;

  // memory-vector results
  if (secondBrainResults.length > 0) {
    message += "**memory-vector**\n";
    for (const ctx of secondBrainResults) {
      const source = ctx.source ? ` (${ctx.source})` : "";
      const similarity = Math.round(ctx.similarity * 100);
      message += `- [${similarity}%]${source} ${ctx.content.substring(0, 200)}`;
      if (ctx.content.length > 200) message += "...";
      message += "\n";
    }
    message += "\n";
  }

  // memory-graph results
  if (graphitiResults.length > 0) {
    message += "**memory-graph**\n";
    for (const fact of graphitiResults) {
      if (typeof fact === "string") {
        message += `- ${fact}\n`;
      } else if (fact.fact) {
        message += `- ${fact.fact}\n`;
      }
    }
    message += "\n";
  }

  message += "---\n";

  return message;
}

main().catch(() => process.exit(0));
