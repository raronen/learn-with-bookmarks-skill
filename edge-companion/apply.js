(function () {
  "use strict";

  const status = document.getElementById("status");
  const GENERATED_ID = "(?:[0-9a-f]{32}|[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})";
  const STAGING_NAME = new RegExp(`^__LWB_STAGING__${GENERATED_ID}$`, "i");
  const ROLLBACK_NAME = new RegExp(`^__LWB_ROLLBACK__${GENERATED_ID}$`, "i");

  function show(message, kind) {
    status.textContent = message;
    status.className = kind || "";
  }

  function call(method, ...args) {
    return new Promise((resolve, reject) => {
      chrome.bookmarks[method](...args, (value) => {
        const error = chrome.runtime.lastError;
        if (error) reject(new Error(error.message));
        else resolve(value);
      });
    });
  }

  async function resolveDestination(path) {
    const roots = await call("getTree");
    if (!Array.isArray(roots) || roots.length !== 1 || !Array.isArray(roots[0].children)) {
      throw new Error("Edge returned an unexpected bookmark root tree.");
    }
    let matches = roots[0].children.filter((node) => !node.url && node.title === path[0]);
    if (matches.length !== 1) {
      throw new Error(`Destination segment '${path[0]}' is ${matches.length ? "ambiguous" : "missing"}.`);
    }
    let current = matches[0];
    for (const segment of path.slice(1)) {
      const children = await call("getChildren", current.id);
      matches = children.filter((node) => !node.url && node.title === segment);
      if (matches.length !== 1) {
        throw new Error(`Destination segment '${segment}' below '${current.title}' is ${matches.length ? "ambiguous" : "missing"}.`);
      }
      current = matches[0];
    }
    return current;
  }

  async function removeNode(node) {
    if (node.url) await call("remove", node.id);
    else await call("removeTree", node.id);
  }

  async function createNode(parentId, node) {
    if (node.type === "bookmark") {
      await call("create", { parentId, title: node.name, url: node.url });
      return 1;
    }
    const folder = await call("create", { parentId, title: node.name });
    let count = 1;
    for (const child of node.children) count += await createNode(folder.id, child);
    return count;
  }

  function newStagingName() {
    const id = typeof crypto.randomUUID === "function"
      ? crypto.randomUUID()
      : [...crypto.getRandomValues(new Uint8Array(16))].map((value) => value.toString(16).padStart(2, "0")).join("");
    return `__LWB_STAGING__${id}`;
  }

  function newRollbackName() {
    return newStagingName().replace("__LWB_STAGING__", "__LWB_ROLLBACK__");
  }

  async function getNode(id) {
    try {
      const nodes = await call("get", id);
      return nodes.length === 1 ? nodes[0] : null;
    } catch (_) {
      return null;
    }
  }

  async function removeNodeIfPresent(id) {
    const node = await getNode(id);
    if (node) await removeNode(node);
  }

  async function recoverAbandonedRollbackFolders(parentId) {
    const children = await call("getChildren", parentId);
    const rollbacks = children.filter((child) => !child.url && ROLLBACK_NAME.test(child.title));
    for (const rollback of rollbacks) {
      const saved = await call("getChildren", rollback.id);
      for (const child of saved) await call("move", child.id, { parentId });
      await call("removeTree", rollback.id);
    }
  }

  async function removeAbandonedStagingFolders(parentId) {
    const children = await call("getChildren", parentId);
    for (const node of children.filter((child) => !child.url && STAGING_NAME.test(child.title))) {
      await call("removeTree", node.id);
    }
  }

  async function stageChildren(parentId, children) {
    await recoverAbandonedRollbackFolders(parentId);
    await removeAbandonedStagingFolders(parentId);
    const staging = await call("create", { parentId, title: newStagingName() });
    let created = 0;
    try {
      for (const child of children) created += await createNode(staging.id, child);
      return { staging, created };
    } catch (error) {
      try { await call("removeTree", staging.id); } catch (_) { /* a later retry removes abandoned staging */ }
      throw error;
    }
  }

  async function restoreRollback(destinationId, rollbackId, originals) {
    if (!rollbackId) return;
    for (const original of originals.sort((left, right) => left.index - right.index)) {
      if (await getNode(original.id)) {
        await call("move", original.id, { parentId: destinationId, index: original.index });
      }
    }
    await removeNodeIfPresent(rollbackId);
  }

  function throwWithRecoveryErrors(error, recoveryErrors) {
    if (recoveryErrors.length === 0) throw error;
    throw new Error(`${error.message} Recovery also encountered: ${recoveryErrors.join("; ")}`);
  }

  async function applyCommand(command) {
    const destination = await resolveDestination(command.destinationPath);
    let removed = 0;

    if (command.type === "removeNamedFolders") {
      const names = new Set(command.names);
      const children = await call("getChildren", destination.id);
      const matches = children.filter((node) => !node.url && names.has(node.title));
      for (const node of matches) {
        await call("removeTree", node.id);
        removed += 1;
      }
      return {
        destinationId: destination.id,
        requestedNames: command.names.length,
        removedFolders: removed
      };
    }

    if (command.type === "upsertManifestTopic") {
      const staged = await stageChildren(destination.id, command.topic.children);
      const children = await call("getChildren", destination.id);
      const matches = children
        .map((node, index) => ({ node, index }))
        .filter(({ node }) => !node.url && node.title === command.topic.name);
      let rollback = null;
      try {
        rollback = await call("create", { parentId: destination.id, title: newRollbackName() });
        for (const { node } of matches) {
          await call("move", node.id, { parentId: rollback.id });
          removed += 1;
        }
        await call("update", staged.staging.id, { title: command.topic.name });
        await call("removeTree", rollback.id);
      } catch (error) {
        const recoveryErrors = [];
        try {
          await restoreRollback(
            destination.id,
            rollback && rollback.id,
            matches.map(({ node, index }) => ({ id: node.id, index }))
          );
        } catch (recoveryError) {
          recoveryErrors.push(`rollback restore failed: ${recoveryError.message}`);
        }
        try {
          await removeNodeIfPresent(staged.staging.id);
        } catch (recoveryError) {
          recoveryErrors.push(`staging cleanup failed: ${recoveryError.message}`);
        }
        throwWithRecoveryErrors(error, recoveryErrors);
      }
      return {
        destinationId: destination.id,
        removedTopicFolders: removed,
        createdNodes: staged.created + 1
      };
    }

    const staged = await stageChildren(destination.id, command.children);
    const children = await call("getChildren", destination.id);
    const originals = children
      .map((node, index) => ({ node, index }))
      .filter(({ node }) => node.id !== staged.staging.id);
    const stagedChildren = await call("getChildren", staged.staging.id);
    let rollback = null;
    try {
      rollback = await call("create", { parentId: destination.id, title: newRollbackName() });
      for (const { node } of originals) {
        await call("move", node.id, { parentId: rollback.id });
        removed += 1;
      }
      for (let index = 0; index < stagedChildren.length; index += 1) {
        await call("move", stagedChildren[index].id, { parentId: destination.id, index });
      }
      await call("removeTree", staged.staging.id);
      await call("removeTree", rollback.id);
    } catch (error) {
      const recoveryErrors = [];
      try {
        await restoreRollback(
          destination.id,
          rollback && rollback.id,
          originals.map(({ node, index }) => ({ id: node.id, index }))
        );
      } catch (recoveryError) {
        recoveryErrors.push(`rollback restore failed: ${recoveryError.message}`);
      }
      for (const node of stagedChildren) {
        try {
          await removeNodeIfPresent(node.id);
        } catch (recoveryError) {
          recoveryErrors.push(`new-node cleanup failed for ${node.id}: ${recoveryError.message}`);
        }
      }
      try {
        await removeNodeIfPresent(staged.staging.id);
      } catch (recoveryError) {
        recoveryErrors.push(`staging cleanup failed: ${recoveryError.message}`);
      }
      throwWithRecoveryErrors(error, recoveryErrors);
    }
    return { destinationId: destination.id, removedChildren: removed, createdNodes: staged.created };
  }

  async function postResult(endpoint, token, result) {
    const resultUrl = new URL("/result", endpoint).href;
    const response = await fetch(resultUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-Companion-Token": token },
      body: JSON.stringify(result),
      cache: "no-store"
    });
    if (!response.ok) throw new Error(`Bridge rejected result with HTTP ${response.status}.`);
  }

  async function run() {
    let request;
    let commandType = "unknown";
    try {
      const query = new URLSearchParams(location.search);
      const keys = [...query.keys()].sort();
      if (keys.length !== 2 || keys[0] !== "endpoint" || keys[1] !== "token") {
        throw new Error("Exactly one endpoint and one token query parameter are required.");
      }
      request = BookmarkCommandCore.validateApplyRequest({
        endpoint: query.get("endpoint"),
        token: query.get("token")
      });
      const response = await fetch(request.endpoint, {
        method: "GET",
        headers: { "X-Companion-Token": request.token },
        cache: "no-store"
      });
      if (!response.ok) throw new Error(`Bridge returned HTTP ${response.status}.`);
      const command = BookmarkCommandCore.validateCommand(await response.json());
      commandType = command.type;
      show(`Applying ${commandType} through Edge Favorites Sync…`);
      if (!navigator.locks) throw new Error("Edge Web Locks support is required to serialize Favorites changes.");
      const details = await navigator.locks.request(
        "learn-with-bookmarks-favorites-write",
        { mode: "exclusive" },
        () => applyCommand(command)
      );
      const result = { version: 1, ok: true, commandType, details };
      await postResult(request.endpoint, request.token, result);
      show(`Success. ${commandType} completed.\nCreated ${details.createdNodes} bookmark nodes.`, "success");
    } catch (error) {
      const result = { version: 1, ok: false, commandType, error: error instanceof Error ? error.message : String(error) };
      if (request) {
        try { await postResult(request.endpoint, request.token, result); } catch (_) { /* visible error remains authoritative */ }
      }
      show(`Failure: ${result.error}`, "failure");
    }
  }

  run();
}());
