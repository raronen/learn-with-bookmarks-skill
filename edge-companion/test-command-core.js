"use strict";

const assert = require("node:assert/strict");
const core = require("./command-core.js");

const valid = {
  version: 1,
  type: "upsertManifestTopic",
  destinationPath: ["Favorites bar", "Imported"],
  topic: {
    type: "folder",
    name: "Topic",
    children: [
      { type: "bookmark", name: "Overview", url: "file:///C:/guide.html" },
      { type: "folder", name: "Flow", children: [{ type: "bookmark", name: "Code", url: "https://example.test/code" }] }
    ]
  }
};

assert.deepEqual(core.validateCommand(valid), valid);
assert.throws(() => core.validateCommand({ ...valid, destinationPath: ["Imported"] }), /Favorites bar/);
assert.throws(() => core.validateCommand({ ...valid, extra: true }), /unsupported property/);
assert.throws(() => core.validateCommand({
  version: 1,
  type: "replaceFolderChildren",
  destinationPath: ["Favorites bar", "Cache"],
  children: [{ type: "bookmark", name: "Bad", url: "javascript:alert(1)" }]
}), /must use http, https, or file/);
assert.deepEqual(
  core.validateCommand({
    version: 1,
    type: "removeNamedFolders",
    destinationPath: ["Favorites bar", "Imported"],
    names: ["Topic A", "Topic B"]
  }),
  {
    version: 1,
    type: "removeNamedFolders",
    destinationPath: ["Favorites bar", "Imported"],
    names: ["Topic A", "Topic B"]
  }
);
assert.throws(() => core.validateCommand({
  version: 1,
  type: "removeNamedFolders",
  destinationPath: ["Favorites bar", "Imported"],
  names: ["Topic", "Topic"]
}), /must not contain duplicates/);
assert.deepEqual(
  core.validateApplyRequest({ endpoint: "http://127.0.0.1:49152/command", token: "A".repeat(43) }),
  { endpoint: "http://127.0.0.1:49152/command", token: "A".repeat(43) }
);
assert.throws(() => core.validateApplyRequest({ endpoint: "http://localhost:49152/command", token: "A".repeat(43) }), /127\.0\.0\.1/);

console.log("command-core tests passed");
