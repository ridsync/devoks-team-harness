#!/usr/bin/env node
// Minimal MCP server for Metro/React Native CDP debugging
// Run with: node --experimental-websocket metro-mcp.js
// Requires Node.js 20+ with --experimental-websocket flag

'use strict';
const http  = require('http');
const readline = require('readline');

const METRO_URL = process.env.METRO_URL || 'http://localhost:8081';

// ─── MCP stdio transport ─────────────────────────────────────────────────────
const rl = readline.createInterface({ input: process.stdin, terminal: false });
const send = (obj) => process.stdout.write(JSON.stringify(obj) + '\n');

// ─── Metro CDP connection ─────────────────────────────────────────────────────
let ws                = null;
let connectingPromise = null; // serialize concurrent ensureConnected() calls
let cmdId             = 1;
const pending         = new Map();
const consoleMsgs     = [];

function fetchMetroWsUrl() {
  return new Promise((resolve, reject) => {
    http.get(`${METRO_URL}/json`, (res) => {
      let raw = '';
      res.on('data', d => raw += d);
      res.on('end', () => {
        try {
          const targets = JSON.parse(raw);
          const target  = Array.isArray(targets) ? targets[0] : null;
          if (target?.webSocketDebuggerUrl) resolve(target.webSocketDebuggerUrl);
          else reject(new Error('No Metro target found in /json'));
        } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

async function doConnect() {
  const wsUrl = await fetchMetroWsUrl();
  ws = new WebSocket(wsUrl);

  await new Promise((resolve, reject) => {
    ws.addEventListener('open',  resolve);
    ws.addEventListener('error', (e) => reject(new Error(String(e.message || e))));
  });

  ws.addEventListener('message', (event) => {
    let msg;
    try { msg = JSON.parse(event.data); } catch { return; }

    // Resolve pending CDP commands
    if (msg.id != null && pending.has(msg.id)) {
      const cb = pending.get(msg.id);
      pending.delete(msg.id);
      cb(msg);
    }

    // Capture console output (Hermes: Runtime.consoleAPICalled)
    if (msg.method === 'Runtime.consoleAPICalled') {
      const { type, args } = msg.params;
      const text = (args || []).map(a => {
        if (a.value != null)        return String(a.value);
        if (a.description != null)  return a.description;
        return JSON.stringify(a);
      }).join(' ');
      consoleMsgs.push({ type, text, timestamp: Date.now() });
      if (consoleMsgs.length > 200) consoleMsgs.shift();
    }

    // Capture console output (legacy Console domain)
    if (msg.method === 'Console.messageAdded') {
      const m = msg.params?.message;
      if (m) {
        consoleMsgs.push({ type: m.level, text: m.text, timestamp: Date.now() });
        if (consoleMsgs.length > 200) consoleMsgs.shift();
      }
    }
  });

  ws.addEventListener('close', () => { ws = null; connectingPromise = null; });

  // Enable domains
  await cdp('Runtime.enable', {});
  await cdp('Console.enable', {}).catch(() => {}); // optional domain
}

async function ensureConnected() {
  if (ws?.readyState === WebSocket.OPEN) return;
  // Serialize concurrent calls — don't create multiple WebSockets
  if (connectingPromise) return connectingPromise;
  connectingPromise = doConnect().finally(() => { connectingPromise = null; });
  return connectingPromise;
}

function cdp(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id      = cmdId++;
    const timeout = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`CDP timeout (10s): ${method}`));
    }, 10_000);
    pending.set(id, (result) => {
      clearTimeout(timeout);
      resolve(result);
    });
    ws.send(JSON.stringify({ id, method, params }));
  });
}

// ─── Tools ───────────────────────────────────────────────────────────────────
const TOOLS = [
  {
    name: 'evaluate_script',
    description: 'Evaluate a JavaScript function in the live React Native app via Metro CDP. Pass an arrow function string.',
    inputSchema: {
      type: 'object',
      properties: {
        function: {
          type: 'string',
          description: 'Arrow function to evaluate, e.g. "() => JSON.stringify(globalThis.__appState__)"'
        }
      },
      required: ['function']
    }
  },
  {
    name: 'list_console_messages',
    description: 'List console messages captured from the React Native app since the MCP server started.',
    inputSchema: {
      type: 'object',
      properties: {
        types: {
          type: 'array',
          items: { type: 'string', enum: ['log', 'warn', 'error', 'info', 'debug', 'warning'] },
          description: 'Filter by level. Omit for all.'
        },
        pageSize: { type: 'integer', description: 'Max messages to return (newest first).' }
      }
    }
  },
  {
    name: 'list_network_requests',
    description: 'Return XHR/fetch requests captured in globalThis.__networkRequests__ (requires app-side instrumentation).',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'get_metro_status',
    description: 'Check Metro bundler status and current WebSocket endpoint.',
    inputSchema: { type: 'object', properties: {} }
  }
];

async function callTool(name, args) {
  if (name === 'get_metro_status') {
    try {
      const wsUrl = await fetchMetroWsUrl();
      const connected = ws?.readyState === WebSocket.OPEN;
      return text(JSON.stringify({ metro: METRO_URL, wsUrl, connected }, null, 2));
    } catch (e) {
      return text(`Metro not reachable: ${e.message}`);
    }
  }

  await ensureConnected();

  if (name === 'evaluate_script') {
    const fn = args.function;
    // Hermes does not properly support awaitPromise:true via CDP.
    // Wrap in JSON.stringify so the result is always a string primitive.
    const expr = `(function() {
  try {
    var __fn = ${fn};
    var __r  = __fn();
    // Detect a thenable (Promise) — return a clear error instead of garbage
    if (__r && typeof __r.then === 'function') {
      return '{"__error":"Function returned a Promise. Use a sync function or resolve the value inside and return it."}';
    }
    return typeof __r === 'string' ? __r : JSON.stringify(__r, null, 2);
  } catch (__e) {
    return JSON.stringify({ __error: __e.message });
  }
})()`;
    const res = await cdp('Runtime.evaluate', {
      expression: expr,
      returnByValue: true
    });
    // CDP response shape: { id, result: { result: { type, value|description } } }
    const remoteObj = res.result?.result;
    const val = remoteObj?.value ?? remoteObj?.description ?? JSON.stringify(res);
    return text(String(val));
  }

  if (name === 'list_console_messages') {
    const { types, pageSize } = args;
    let msgs = [...consoleMsgs];
    if (types?.length) msgs = msgs.filter(m => types.includes(m.type));
    if (pageSize)       msgs = msgs.slice(-pageSize);
    return text(msgs.length ? JSON.stringify(msgs, null, 2) : '(no messages captured yet)');
  }

  if (name === 'list_network_requests') {
    const res = await cdp('Runtime.evaluate', {
      expression: 'JSON.stringify(globalThis.__networkRequests__ || [])',
      returnByValue: true
    });
    return text(res.result?.result?.value ?? '[]');
  }

  throw new Error(`Unknown tool: ${name}`);
}

const text = (t) => ({ content: [{ type: 'text', text: t }] });

// ─── MCP request handler ──────────────────────────────────────────────────────
rl.on('line', async (line) => {
  const trimmed = line.trim();
  if (!trimmed) return;

  let msg;
  try { msg = JSON.parse(trimmed); } catch { return; }

  const { id, method, params } = msg;

  // Notifications have no id — don't respond
  if (id == null) return;

  try {
    if (method === 'initialize') {
      send({ jsonrpc: '2.0', id, result: {
        protocolVersion: '2024-11-05',
        capabilities: { tools: {} },
        serverInfo: { name: 'metro-mcp', version: '1.0.0' }
      }});

      // Connect eagerly so console capture starts immediately
      ensureConnected().catch(() => {});

    } else if (method === 'tools/list') {
      send({ jsonrpc: '2.0', id, result: { tools: TOOLS } });

    } else if (method === 'tools/call') {
      const result = await callTool(params?.name, params?.arguments || {});
      send({ jsonrpc: '2.0', id, result });

    } else if (method === 'ping') {
      send({ jsonrpc: '2.0', id, result: {} });

    } else {
      send({ jsonrpc: '2.0', id, error: { code: -32601, message: `Method not found: ${method}` } });
    }
  } catch (err) {
    send({ jsonrpc: '2.0', id, error: { code: -32603, message: err.message } });
  }
});

process.stdin.resume();
