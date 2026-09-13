#!/usr/bin/env node
// inject_bridge.js - Insert the localStorage persistence bridge into the
// generated love.js runtime, immediately before its IDBFS mount/populate
// statement. That is the only point inside the module closure where FS and
// Module are both in scope before the game boots. Fails loudly when the
// runtime layout changes (marker missing) so the build can't silently ship
// without persistence.
//
// Usage: node tools/inject_bridge.js <dist-love.js> <storage-bridge.js>
const fs = require("fs");

const [runtimePath, bridgePath] = process.argv.slice(2);
if (!runtimePath || !bridgePath) {
    console.error("usage: node tools/inject_bridge.js <dist-love.js> <storage-bridge.js>");
    process.exit(1);
}

const runtime = fs.readFileSync(runtimePath, "utf8");
const bridge = fs.readFileSync(bridgePath, "utf8");
const MARKER = 'Module.addRunDependency("IDBFS_sync")';

if (!runtime.includes(MARKER)) {
    console.error("inject_bridge: IDBFS marker not found in " + runtimePath);
    process.exit(1);
}

fs.writeFileSync(runtimePath, runtime.replace(MARKER, bridge + "\n" + MARKER));
console.log("inject_bridge: storage bridge injected into " + runtimePath);
