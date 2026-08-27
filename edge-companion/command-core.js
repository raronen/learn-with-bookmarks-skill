(function (root, factory) {
  const api = factory();
  if (typeof module === "object" && module.exports) {
    module.exports = api;
  } else {
    root.BookmarkCommandCore = api;
  }
}(typeof globalThis !== "undefined" ? globalThis : this, function () {
  "use strict";

  const MAX_DEPTH = 32;
  const MAX_NODES = 10000;
  const MAX_NAME = 1024;
  const ALLOWED_PROTOCOLS = new Set(["http:", "https:", "file:"]);

  function fail(message) {
    throw new Error(message);
  }

  function isRecord(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
  }

  function assertKeys(value, required, optional, context) {
    if (!isRecord(value)) fail(`${context} must be an object.`);
    const allowed = required.concat(optional);
    for (const key of Object.keys(value)) {
      if (!allowed.includes(key)) fail(`${context} contains unsupported property '${key}'.`);
    }
    for (const key of required) {
      if (!(key in value)) fail(`${context}.${key} is required.`);
    }
  }

  function validateName(value, context) {
    if (typeof value !== "string" || value.trim() !== value || value.length === 0 || value.length > MAX_NAME) {
      fail(`${context} must be a non-empty, trimmed string of at most ${MAX_NAME} characters.`);
    }
    if (/[\u0000-\u001f\u007f]/.test(value)) fail(`${context} must not contain control characters.`);
    return value;
  }

  function validateUrl(value, context) {
    if (typeof value !== "string" || value.length === 0 || value.length > 8192) {
      fail(`${context} must be a non-empty URL string of at most 8192 characters.`);
    }
    let parsed;
    try {
      parsed = new URL(value);
    } catch (_) {
      fail(`${context} is not an absolute URL.`);
    }
    if (!ALLOWED_PROTOCOLS.has(parsed.protocol)) {
      fail(`${context} must use http, https, or file.`);
    }
    return value;
  }

  function validateNode(node, context, depth, state) {
    if (depth > MAX_DEPTH) fail(`Bookmark tree exceeds maximum depth ${MAX_DEPTH}.`);
    state.count += 1;
    if (state.count > MAX_NODES) fail(`Bookmark tree exceeds maximum size ${MAX_NODES}.`);
    if (!isRecord(node) || (node.type !== "folder" && node.type !== "bookmark")) {
      fail(`${context}.type must be exactly 'folder' or 'bookmark'.`);
    }

    if (node.type === "bookmark") {
      assertKeys(node, ["type", "name", "url"], [], context);
      return { type: "bookmark", name: validateName(node.name, `${context}.name`), url: validateUrl(node.url, `${context}.url`) };
    }

    assertKeys(node, ["type", "name", "children"], [], context);
    if (!Array.isArray(node.children)) fail(`${context}.children must be an array.`);
    return {
      type: "folder",
      name: validateName(node.name, `${context}.name`),
      children: node.children.map((child, index) => validateNode(child, `${context}.children[${index}]`, depth + 1, state))
    };
  }

  function validatePath(path) {
    if (!Array.isArray(path) || path.length === 0 || path.length > MAX_DEPTH) {
      fail(`destinationPath must be a non-empty array with at most ${MAX_DEPTH} segments.`);
    }
    const result = path.map((segment, index) => validateName(segment, `destinationPath[${index}]`));
    if (result[0] !== "Favorites bar") fail("destinationPath must start with exactly 'Favorites bar'.");
    return result;
  }

  function validateCommand(command) {
    if (!isRecord(command)) fail("Command must be an object.");
    if (command.version !== 1) fail("Command version must be exactly 1.");
    if (command.type === "upsertManifestTopic") {
      assertKeys(command, ["version", "type", "destinationPath", "topic"], [], "command");
      const topic = validateNode(command.topic, "topic", 0, { count: 0 });
      if (topic.type !== "folder") fail("topic must be a folder.");
      return { version: 1, type: command.type, destinationPath: validatePath(command.destinationPath), topic };
    }
    if (command.type === "replaceFolderChildren") {
      assertKeys(command, ["version", "type", "destinationPath", "children"], [], "command");
      if (!Array.isArray(command.children)) fail("children must be an array.");
      const state = { count: 0 };
      return {
        version: 1,
        type: command.type,
        destinationPath: validatePath(command.destinationPath),
        children: command.children.map((node, index) => validateNode(node, `children[${index}]`, 0, state))
      };
    }
    if (command.type === "removeNamedFolders") {
      assertKeys(command, ["version", "type", "destinationPath", "names"], [], "command");
      if (!Array.isArray(command.names) || command.names.length === 0 || command.names.length > 1000) {
        fail("names must be a non-empty array with at most 1000 entries.");
      }
      const names = command.names.map((name, index) => validateName(name, `names[${index}]`));
      if (new Set(names).size !== names.length) fail("names must not contain duplicates.");
      return { version: 1, type: command.type, destinationPath: validatePath(command.destinationPath), names };
    }
    fail("Command type must be exactly 'upsertManifestTopic', 'replaceFolderChildren', or 'removeNamedFolders'.");
  }

  function validateApplyRequest(value) {
    if (!isRecord(value)) fail("Apply request is invalid.");
    const endpoint = new URL(value.endpoint);
    const port = Number(endpoint.port);
    if (endpoint.protocol !== "http:" || endpoint.hostname !== "127.0.0.1" ||
        !Number.isInteger(port) || port < 1 || port > 65535 ||
        endpoint.username || endpoint.password || endpoint.hash ||
        endpoint.pathname !== "/command" || endpoint.search) {
      fail("endpoint must be exactly http://127.0.0.1:<port>/command.");
    }
    if (typeof value.token !== "string" || !/^[A-Za-z0-9_-]{43,128}$/.test(value.token)) {
      fail("token must be a high-entropy base64url value.");
    }
    return { endpoint: endpoint.href, token: value.token };
  }

  return { validateCommand, validateApplyRequest };
}));
