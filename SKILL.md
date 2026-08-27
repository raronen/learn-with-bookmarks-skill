---
name: learn-with-bookmarks
description: Investigate and teach a technical topic across one or more repositories, then create a durable local HTML learning guide with a collapsed bookmark tree followed by mandatory Architecture, Sequence, and Data Flow diagrams plus applicable detailed, color-coded C4, component, activity, flow, decision, state, or code diagrams, direct component-specific telemetry query links when known, and a structured bookmark folder published safely through the Edge companion API or browser import. Use when the user says they want to learn, understand, trace, or get an overview of a feature, flow, architecture, incident, PR, or recent code changes and wants diagrams plus source, telemetry, or bookmark links.
---

# Learn with bookmarks

Turn a learning request into a durable, visual, source-linked study pack.

Invoke as:

```text
/learn-with-bookmarks <topic or question>
```

Natural-language triggers also include:

- "I want to learn how X works."
- "Explain these recent changes and bookmark the code."
- "Teach me this PR."
- "Explain what PR 12345 changes."
- "Create a visual guide for this pull request."
- "Trace this flow across these repositories."
- "Create a visual learning guide for X."

## Required outcome

Complete all of the following:

1. Investigate the topic in every relevant repository.
2. Explain the current behavior and, when relevant, the before/after behavior.
3. Create a self-contained local HTML overview with a collapsed bookmark tree
   first, followed by detailed, color-coded diagrams applicable to the topic.
4. Make every diagram node clickable when a precise source or related bookmark
   exists.
5. When a component's telemetry is known, add a clearly named `Telemetry` link
   to that component's applicable diagram nodes. Place a clearly named `Code`
   link beside every `Telemetry` link when the implementation is hosted in Azure
   DevOps. `Telemetry` must open the exact query or view scoped to that node, not
   a generic workspace home; `Code` must open the corresponding implementation or
   telemetry-emission code.
6. Add applicable Example, Before/After, Hardening, Cross-repo, and Tests
   learning views with prominent same-page navigation.
7. Always include an **Architecture Diagram**, **Sequence Diagram**, and
   **Data Flow Diagram**.
8. Create detailed sub-bookmarks that trace the code's execution path in runtime
   order, including cross-service and cross-repository handoffs.
9. Create one import-ready HTML file for Chrome and Microsoft Edge. When the
   Edge companion is installed, publish the same complete tree automatically
   through Edge's official bookmarks API and require its successful bridge result.
10. Never modify a browser's `Bookmarks` profile file directly. Raw Chromium
    profile writes bypass Favorites/Bookmarks Sync metadata and can flatten,
    reparent, duplicate, or restore unrelated folders. All automated movement,
    grouping, replacement, and restoration must use the Edge companion API.
11. Keep all generated artifacts in durable storage, never session state or a temporary directory.

## Beginner-first teaching baseline

Unless the user explicitly asks for an expert-only treatment, write every guide
so that a new joiner with no prior knowledge of the product, repository, or
domain can understand it. Prefer plain, respectful language over unexplained
jargon; "for beginners" must mean more context and clearer teaching, not a
patronizing tone or reduced technical accuracy.

Before presenting implementation details:

1. Add a prominent **Start here** section that explains:
   - what the product or subsystem is;
   - what user or business problem it solves;
   - where the selected feature sits in the larger system;
   - why the feature exists and what would happen without it;
   - which parts are authoritative state versus caches, replicas, indexes,
    projections, queues, or other disposable/derived state.
2. Introduce one realistic end-to-end example in familiar language and reuse it
   consistently throughout the terminology, diagrams, failure paths, and tests.
3. Define every domain term, acronym, internal codename, and overloaded word on
   first use. For each important term, explain:
   - what it is in plain English;
   - why this system needs it;
   - what it contains or controls;
   - what it is commonly confused with or explicitly is not;
   - a concrete example or analogy when that improves understanding.
4. Give the reader a compact mental model in one or two sentences before the
   detailed architecture. A useful pattern is: "The system does X so that Y;
   when Z fails, it recovers by W."
5. Use progressive disclosure:
   - begin with product context and the happy path;
   - then introduce components and terminology;
   - then show persistence, concurrency, failure, recovery, and optimization;
   - keep precise source links available without requiring source-code knowledge
    to understand the main story.

### Concrete-example rule for abstract mechanics

When the topic contains abstract mechanics such as partitioning, hashing,
concurrency, caching, queues, fan-out, retries, batching, or distributed
coordination, do not stop at an analogy or architecture diagram. Add a small,
realistic, row-level or request-level example that:

- uses named entities and concrete sample values that remain consistent across
  the walkthrough;
- shows the input before processing, the exact per-step transformation or
  movement, and the final output;
- identifies what each machine, process, worker, task, or thread does, including
  which work happens independently and which state is shared;
- distinguishes logical units from physical resources, such as partitions from
  machines and runtime tasks from permanently dedicated operating-system threads;
- quantifies the work with small numbers, then compares the unoptimized and
  optimized paths (for example, source scans, row visits, requests, bytes, or
  retries saved);
- explains the cost paid for the optimization, such as hashing, buffering,
  queueing, coordination, memory, or network transfer;
- clearly labels sample hash values, timings, assignments, or counts as
  illustrative when the exact runtime values cannot be reproduced, while keeping
  verified implementation mechanics and source links separate and explicit.

Prefer tables, labeled buckets, per-machine panels, and before/after counts over
generic prose. A reader should be able to manually trace one concrete entity
through every worker and explain where the saved work comes from.

For every diagram, add a short **How to read it** paragraph immediately before
the visual. Explain the reading direction, the scenario being shown, unfamiliar
participants, and the one key takeaway. Diagram node labels must prefer a plain
role followed by the code name, for example `Official cache index (Catalog)`,
rather than showing only an internal type or method name.

Before publishing, perform a new-joiner pass:

- Could a reader explain the feature's purpose before seeing a class or method?
- Is every acronym and internal term expanded before use?
- Does each technical term have enough context to distinguish it from nearby
  concepts?
- Can the concrete example be followed from input through result and recovery?
- Can each diagram be understood without first reading the source code?
- Are advanced details preserved but placed after the foundational explanation?

If any answer is no, revise the guide before publication.

## Durable locations

Use this root unless the user explicitly chooses another:

```text
C:\Users\<user>\OneDrive - Microsoft\Documents\Learning Bookmarks
```

Create one filesystem folder per topic:

```text
Learning Bookmarks\
  <topic-slug>\
    <topic-slug>-overview.html
    <topic-slug>-bookmarks.json
    import-<topic-slug>-bookmarks.html
```

The JSON file is the publisher manifest, not a browser-import format. Chrome and
Edge import Netscape bookmark HTML.

Never place durable output in:

- `%TEMP%`
- `.copilot\session-state`
- repository source folders
- attachment staging folders

## Starting from Home or multiple repositories

The user may start in a Home/chat session and select several repositories.

1. Call `list_projects` to discover configured projects.
2. If the repositories are ambiguous, ask one focused question at a time.
3. For every repository outside the current session, create a coordinated research
   session in that project.
4. Give each child a complete prompt containing:
   - the learning question;
   - the requested date/author/commit scope, if any;
   - the facts and call chains to trace;
   - a requirement to report precise repo-relative paths, symbols, line ranges,
     commits, tests, before/after behavior, and verified component-specific
     telemetry queries or views when known;
   - an instruction not to modify code.
5. Run independent repository research in parallel.
6. Wait for and aggregate all child reports before generating artifacts.
7. For the current repository, investigate inline rather than creating a redundant
   child session.

Use the `orchestrate` skill's cross-repo research workflow when available.

## ARM-fronted feature learning

Treat a feature as **behind ARM** when clients reach it through an Azure Resource
Manager resource ID, management-plane REST operation, ARM proxy, resource
provider route, or `management.azure.com` endpoint before the request reaches
the owning service.

For these features, use the ARM MCP during investigation to build the true
end-to-end architecture picture. Do not draw ARM as a generic unexplained box or
start the flow at the downstream service merely because that code is in the
current repository.

Use ARM MCP to identify, when available:

- the public ARM operation, HTTP method, path, API version, and resource type;
- subscription, resource group, provider namespace, parent/child resource, and
  resource-ID semantics;
- ARM authentication, authorization, policy, validation, and routing boundaries;
- resource-provider registration and the handoff from ARM to the owning service;
- request/response transformations, headers, correlation identifiers, async
  operation handling, and error mapping;
- relevant ARM resources or deployments that clarify the runtime topology.

Then use Azure DevOps MCP or repository investigation for the implementation
behind the ARM handoff. Correlate the ARM-facing contract with the downstream
controller/endpoint, authorization, orchestration, storage, and response path.
Do not infer internal ARM implementation details that the MCP evidence does not
expose.

If it is unclear whether the feature is ARM-fronted, inspect its public endpoint,
resource ID, API contract, and callers. If ambiguity remains, ask one focused
question: **"Is this feature invoked through Azure Resource Manager, or directly
through the service endpoint?"**

### Required ARM end-to-end diagrams

For an ARM-fronted feature, all three mandatory diagrams must include the
management-plane boundary:

1. **Architecture Diagram**
   - Show client/tool -> ARM -> resource provider/service -> dependencies.
   - Mark trust, ownership, repository, deployment, and external-system
     boundaries.
2. **Sequence Diagram**
   - Start with the client request to ARM.
   - Include ARM validation/routing, downstream service calls, async polling or
     callbacks when present, and the response/error path back through ARM.
3. **Data Flow Diagram**
   - Show resource identifiers, tokens/claims, API-versioned payloads, headers,
     transformed requests, persisted data, and returned results crossing each
     boundary.

Add a **Cross-repo** view when ARM-facing and downstream implementation live in
different repositories. Make ARM and downstream nodes clickable to precise ARM
documentation, MCP-discovered resources, API specifications, source code, tests,
or related bookmarks whenever such links exist.

## Pull request learning mode

Enter PR learning mode when the user supplies or refers to a pull request, PR
URL, PR number, review, proposed change, or branch diff. This mode explains both
the architecture and the delta introduced by the PR.

### Resolve the pull request

Prefer Azure DevOps MCP repository and pull-request tools over scraping HTML or
guessing from a local checkout.

1. If the user provides a full PR URL, parse its organization, project,
   repository, and PR ID. Fetch that PR directly.
2. If the current repository plus PR ID identifies exactly one PR, use it.
3. If the PR location is not uniquely known, ask one focused question:
   **"Which service or repository is this PR related to?"**
   - Offer known service/repository names as choices when available.
   - Do not ask for organization, project, repository, and PR ID in one bundled
     question.
4. Resolve the service to candidate Azure DevOps repositories. Use Azure DevOps
   MCP to list/search PRs in those repositories, including active and recently
   completed PRs when the user's wording requires it.
5. If several PRs still match, ask the user to select from concise choices
   containing PR ID, title, repository, author, and status.
6. Fetch PR metadata, latest iteration, changed files, actual line diffs,
   source/target refs, commits, and comment threads when review discussion
   materially explains the change.
7. Record the resolved project, repository, PR ID, source branch, target branch,
   latest iteration, and comparison base before generating links.

Never select a PR merely because its number or title looks similar. If Azure
DevOps MCP is unavailable, use authenticated Azure DevOps APIs or a local
source/target diff only when identity can still be established reliably. State
when the analysis is based on a local approximation rather than the canonical PR
iteration.

### Investigate the PR delta

Do not summarize only the changed lines. For every meaningful changed area:

1. Read the complete changed methods/types plus their surrounding component.
2. Trace callers, callees, contracts, configuration, and tests affected by the
   change.
3. Compare target/base behavior with the PR behavior.
4. Classify behavior explicitly as:
   - **Existing and unchanged** - still participates but is not modified;
   - **New** - introduced by the PR;
   - **Changed/hardened** - existing behavior altered by the PR;
   - **Removed/replaced** - behavior deleted or superseded by the PR.
5. Distinguish code movement/refactoring from real behavior changes.
6. Identify compatibility, rollout, failure-path, security, performance,
   concurrency, telemetry, and test implications when applicable.
7. Treat tests as behavioral evidence, not proof that every scenario is covered.
8. Include unresolved review comments or later iterations only when they alter
   the current understanding; clearly label superseded discussion.

### PR-focused HTML

PR learning guides must emphasize change status throughout:

- use the existing/new/changed/removed palette as the primary visual language;
- put a visible status badge on every diagram node, including unchanged context;
- use solid borders for PR-touched nodes and a lighter or dashed treatment for
  unchanged context;
- include **Before / After** navigation and content;
- begin with a compact PR summary containing title, ID, repository, author,
  status, source -> target branch, iteration, changed-file count, and scope;
- show unchanged nodes needed to understand the end-to-end flow rather than
  drawing only disconnected changed lines;
- visually distinguish a changed implementation from an unchanged caller,
  dependency, contract, or downstream effect;
- include an impact map that connects changed files to affected components,
  flows, tests, and repositories when applicable;
- explain what deliberately does **not** change, especially public contracts,
  authorization boundaries, persistence, execution behavior, or deployment.

In addition to the mandatory Architecture, Sequence, and Data Flow diagrams,
consider these optional PR-focused diagrams:

- a High-Level Architecture, C4, or Component diagram showing affected and
  unaffected boundaries;
- a Before/After flowchart for behavioral changes;
- an Activity diagram when parallel workflow or responsibility changes;
- a Code/Class diagram when ownership or type relationships change;
- a Decision Tree when branching/routing rules change;
- a State Machine when transitions change.

## Investigation quality bar

Do not create diagrams from commit messages alone.

Trace:

- API or event entry points;
- parsing and validation;
- orchestration and branching;
- service and repository calls;
- authorization and security boundaries;
- data transformation and rewriting;
- output assembly and execution;
- failure paths and feature gates;
- tests proving the important behavior;
- telemetry emitted, component identifiers/correlation fields, telemetry stores,
  and existing queries, dashboards, or workbooks that observe each material
  component when this evidence is available;
- relevant historical implementation for "before" nodes.

Treat telemetry as evidence, not an assumption. Record the exact query text or
saved-query/view identity, data scope, and the strongest verified filter for the
specific runtime place represented by each node. An end-to-end correlation key,
service prefix, or operation family may be the common base of several queries,
but it is not sufficient by itself for links on different components or stages.
Each query must add a verified discriminator such as source, directory, role,
activity type, operation, level, event name/text, or component identifier that
narrows results to that node's place in the flow. Reuse a query only when nodes
are repeated views of the same runtime place. If a distinct node-specific
mapping cannot be established, omit its telemetry link and state the evidence
gap rather than attaching a broad flow-wide query.

For recent changes:

1. Identify the author and commits.
2. Separate merge commits from implementation commits.
3. Compare parent/current versions for removed behavior.
4. Explain adjacent hardening commits when they materially affect the same flow.
5. Clearly distinguish observed code from inference.

## Source-link rules

Prefer permanent web links that the user can open outside the local checkout.

### Telemetry deep links

When telemetry for a diagram node is known, provide a durable deep link labeled
`Telemetry` that opens the exact query or saved view for that specific runtime
place. This applies to Architecture, Sequence, Data Flow, Flowchart/Decision
Tree, Component, C4, Activity, State Machine, and Code/Class nodes whenever the
node has observable, distinguishable telemetry.

- Prefer the telemetry system's native share/copy-link feature, such as Azure
  Monitor Logs/Application Insights, Azure Data Explorer, a workbook, or an
  exact dashboard panel.
- The destination must preserve or identify the executable query and its data
  scope. Start with the verified end-to-end correlation filter when useful, then
  add verified service, component, directory, operation, activity type, role,
  resource, level, event, or source predicates that isolate the runtime place
  shown by the node. A workspace, cluster, dashboard home, or undifferentiated
  flow-wide query is not sufficient.
- Never reuse one unchanged broad correlation query across different components,
  layers, stages, decisions, caches, failure paths, or response paths. Reuse is
  allowed only for repeated appearances of the same runtime place in different
  diagrams.
- When the telemetry schema cannot distinguish a node from the broader flow,
  omit that node's `Telemetry` link and document the evidence gap. Do not add a
  cosmetic scope label, projection, comment, or constant without a narrowing
  predicate and call it node-specific.
- Use a sensible reusable time-range behavior. Prefer a destination that lets the
  viewer choose or override time unless a fixed incident window is essential;
  label fixed-window links with that window.
- End row-returning exploratory telemetry queries with `| limit 10` by default
  so opening a guide does not launch an unnecessarily long or expensive query.
  Place the limit after the final ordering operator. A bounded aggregate, scalar,
  or saved view that cannot return an unbounded row set does not need this limit.
- Verify a representative telemetry link for every telemetry system used. It
  must open the intended workspace/cluster/view and restore the expected
  node-specific query or saved view. Also compare every distinct telemetry link
  in the rendered guide: different runtime places must have different verified
  narrowing predicates, not merely different labels or URLs.
- Never guess table names, fields, filters, workspace/cluster identifiers, or
  query text. Never embed credentials, access tokens, secrets, customer data, or
  sensitive identifiers in the URL. Follow the telemetry system's access model.
- HTML-encode `&` as `&amp;` in generated HTML. Keep the underlying URL
  correctly URL-encoded.
- In Azure DevOps-backed guides, pair every visible `Telemetry` link with a
  visible adjacent `Code` link to the most precise implementation or emission
  site for that node. Even when several nodes share one correlated telemetry
  query, keep each node's `Code` destination specific to its own code. Do not use
  a repository summary page when a file and line range are known.

### Azure DevOps

Use this exact line-selection shape:

```text
https://<org>.visualstudio.com/<project>/_git/<repo>?path=/<repo-path>&version=GBmain&line=<start>&lineEnd=<end>&lineStartColumn=5&lineEndColumn=6&lineStyle=plain&_a=contents
```

For historical code, pin the commit:

```text
version=GC<full-commit-sha>
```

Always include:

```text
lineStartColumn=5&lineEndColumn=6
```

HTML-encode `&` as `&amp;` inside generated HTML.

#### Azure DevOps pull-request file links

In PR learning mode, links to changed code must open the PR **Files** experience,
not the repository contents page. Use the resolved PR metadata and this shape:

```text
https://<org>.visualstudio.com/<project>/_git/<repo>/pullrequest/<pr-id>?path=/<repo-path>&version=GB<target-branch>&line=<start>&lineEnd=<end>&lineStartColumn=<start-column>&lineEndColumn=<end-column>&type=2&lineStyle=plain&_a=files&iteration=<iteration>&base=<base>
```

Example:

```text
https://msazure.visualstudio.com/One/_git/Mgmt-AppInsights-DevExp-API/pullrequest/16459511?path=/Draft/Draft.Role/src/dal/kusto/compiler/aiOmsUnifiedCompiler.ts&version=GBmaster&line=14&lineEnd=14&lineStartColumn=33&lineEndColumn=57&type=2&lineStyle=plain&_a=files&iteration=1&base=0
```

PR-link requirements:

- use the actual PR ID, target branch, selected iteration, and comparison base;
- preserve `type=2`, `lineStyle=plain`, and `_a=files`;
- URL-encode branch names and paths where required;
- use precise line and column ranges from the PR side being referenced; do not
  default every PR link to columns 5 and 6;
- link changed/new code to its visible range in the selected PR iteration;
- for removed/base behavior, link to the base side or a commit-pinned historical
  contents link when that is clearer and stable;
- for unchanged context, use a normal branch/commit contents link unless the
  unchanged line is intentionally shown in the PR diff;
- label links `PR change`, `Before`, `Current PR`, `Unchanged implementation`,
  `Tests`, or similarly so the destination is unambiguous;
- verify a representative link from each changed file opens the expected PR,
  iteration, file, diff side, and selected range before publishing;
- HTML-encode every `&` as `&amp;` in the overview HTML.

### GitHub

Use commit-pinned line links when possible:

```text
https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<start>-L<end>
```

### Local-only repositories

Use a `file:///` URI and label it as local. Prefer a web remote when one exists.

## Overview HTML requirements

The first bookmark in every topic folder must be:

```text
00 - Open <Topic> Overview
```

It must point to the durable local overview HTML.

The page must be self-contained:

- inline CSS;
- no CDN;
- no external JavaScript;
- readable offline;
- printable;
- navigation links to every section;
- a generated date and investigated repository list.

### Page navigation and learning views

Immediately below the embedded bookmark tree, include a prominent navigation bar
of large, readable buttons. **Bookmarks** is always included and links back to
the embedded tree. Add the other buttons and corresponding sections only when
applicable:

| View | Include when | Expected content |
|---|---|---|
| **Example** | A realistic request, query, event, entity, or scenario makes the behavior easier to understand. | A concrete walkthrough using the most suitable flowchart, sequence, activity, decision, or state diagram, with real source links. |
| **Before / After** | The topic covers recent changes, migration, refactoring, replacement, or behavioral differences. | Side-by-side or clearly connected old/new paths, including commit-pinned links for historical code. |
| **Hardening** | Security, validation, authorization, limits, retries, deduplication, concurrency, ordering, failure handling, or resilience materially affects the topic. | Threat/failure paths, safeguards, edge cases, and the tests or telemetry proving them. |
| **Cross-repo** | More than one repository, service, SDK, deployment unit, or ownership boundary participates. | Repository ownership, contracts, protocols, handoffs, and source links grouped by repository. |
| **Tests** | Tests provide useful behavioral evidence or clarify edge cases. | A visual or tabular map from behavior to test, including test names, scenarios, and direct source links. |
| **Bookmarks** | Always. | An anchor back to the collapsed bookmark tree at the top of the page. |

Navigation behavior:

- order optional buttons as `Example`, `Before / After`, `Hardening`,
  `Cross-repo`, `Tests`, then `Bookmarks`;
- omit buttons whose sections are not present;
- make the navigation bar sticky when practical so it remains available while
  reading long diagrams;
- use clear section anchors and smooth scrolling where supported;
- style buttons with a high-contrast selected/hover/focus state;
- do not open a new tab for same-page section navigation;
- the **Bookmarks** button scrolls to the embedded tree; it is not a duplicate
  browser bookmark.

These are thematic learning views, not additional diagram types. Each view may
contain one or more applicable diagram types from the catalog below. Reuse or
cross-link an existing diagram instead of duplicating the same content.

In PR learning mode, **Before / After** is mandatory. **Tests**, **Hardening**,
and **Cross-repo** remain applicability-driven but should be included whenever
the PR supplies meaningful evidence for those views.

### Mandatory bookmark tree at the top

At the top of the overview page, before every diagram section, include an embedded
bookmark-browser tree that mirrors the topic's bookmark manifest.

The publisher generates this tree automatically from the manifest. The overview
HTML must contain these markers immediately after the page header:

```html
<!-- LEARNING-BOOKMARK-TREE:START -->
<!-- LEARNING-BOOKMARK-TREE:END -->
```

Required behavior:

- the topic root starts expanded so its direct links and first-level folders are
  immediately visible;
- every folder below the topic root starts collapsed;
- clicking a folder row expands or collapses it without leaving the page;
- clicking a link opens it in a new browser tab;
- the overview page stays open, preserving the expanded tree state;
- folders and links are visually distinct;
- nested indentation clearly communicates hierarchy;
- keyboard navigation uses native browser behavior;
- no external library or network resource is required;
- the tree order and names exactly match the generated browser bookmarks;
- the tree remains usable independently of the browser bookmark popup.

The generated tree uses native `<details>` and `<summary>` elements. Add the
`open` attribute only to the topic-root `<details>` element. Never add it to
nested folders. Links must use:

```html
target="_blank" rel="noopener noreferrer"
```

Do not manually duplicate the manifest into the tree. Generate the manifest
first, then run the publisher; it replaces the marker block with the canonical
tree. This prevents the HTML tree and browser bookmark hierarchies from drifting.

### Mandatory visual language

Use these colors consistently:

| Meaning | Fill | Border | Text |
|---|---|---|---|
| Existing behavior | `#dbeafe` | `#2563eb` | `#172554` |
| New behavior | `#dcfce7` | `#16a34a` | `#14532d` |
| Changed/hardened behavior | `#fef3c7` | `#d97706` | `#78350f` |
| Removed/replaced behavior | `#fee2e2` | `#dc2626` | `#7f1d1d` |

Include a visible legend.

When the learning topic is not about a change over time, use a role-based palette
instead of forcing the existing/new/changed/removed meanings:

| Meaning | Fill | Border | Text |
|---|---|---|---|
| External actor or system | `#ede9fe` | `#7c3aed` | `#4c1d95` |
| Service or container | `#dbeafe` | `#2563eb` | `#172554` |
| Component or module | `#dcfce7` | `#16a34a` | `#14532d` |
| Data store or durable state | `#fce7f3` | `#db2777` | `#831843` |
| Decision, rule, or branch | `#fef3c7` | `#d97706` | `#78350f` |
| Failure, rejection, or terminal error | `#fee2e2` | `#dc2626` | `#7f1d1d` |
| Runtime state or transition | `#cffafe` | `#0891b2` | `#164e63` |

Never mix the change-status palette and role-based palette without a legend that
explicitly explains both dimensions. Do not rely on color alone; use labels,
icons, border styles, or status badges as a second signal.

### Diagram section selection and order

After the collapsed bookmark tree and navigation, create these three baseline
sections for every learning guide:

1. **Architecture Diagram**
   - Show the topic's boundary, major actors/systems/services/components, key
     dependencies, and ownership.
   - Adjust depth to the topic: system-level for broad subjects and
     component/module-level for narrow subjects.
2. **Sequence Diagram**
   - Show the primary runtime interaction in temporal order, including request,
     response, asynchronous handoff, failure, or callback paths as applicable.
   - For a static library or build-time topic, show the most meaningful
     invocation, compilation, configuration, initialization, or generation
     sequence instead of inventing runtime calls.
3. **Data Flow Diagram**
   - Show where relevant data originates, how it is validated/transformed,
     where it crosses trust or service boundaries, where it is stored/cached,
     and what output it becomes.
   - Label data carried on arrows and distinguish processes, external entities,
     and data stores.

These diagrams are mandatory even when concise. They must provide three distinct
views and must not be copies of one another.

### Mandatory end-to-end detail level

Treat the Architecture and Sequence diagrams as the guide's primary teaching
artifacts, not as summaries. Give them the same depth as the investigated runtime
trace even when the user does not explicitly ask for extra detail.

For every **Architecture Diagram**:

- include every materially participating service, deployable unit, gateway,
  orchestrator, module, identity component, queue, cache, and data store that is
  supported by evidence;
- expand important services into their internal components when those components
  own distinct runtime responsibilities; do not collapse a traced chain into one
  generic service box;
- state what each node does in this flow, not merely its product or class name;
- label every meaningful connector with the concrete operation or protocol and
  the important data carried, such as identifiers, tokens, claims, request DTOs,
  events, commands, configuration, persisted records, status, or errors;
- show repository, service, deployment, trust, tenant, region, and external-system
  boundaries whenever they affect ownership or execution;
- show synchronous, asynchronous, parallel, retry, polling, callback, fan-out,
  fan-in, and rollback paths explicitly instead of describing them only in prose;
- retain important external or unavailable components as evidence-qualified nodes
  and clearly label what is observed versus inferred or not present in the
  investigated repositories.

For every **Sequence Diagram**:

- include all materially distinct participants found in the end-to-end trace,
  including front doors, middleware, validators, handlers, orchestrators, stores,
  downstream services, workers, callbacks, and the initiating client;
- show the complete primary path from the first externally observable request or
  trigger through the final response, status update, callback, or persisted result;
- label each message with the real method, endpoint, command, event, or operation
  when known, followed by the key payload fields or result passed between
  participants;
- show request parsing, authentication, authorization, validation, enrichment,
  orchestration decisions, persistence, downstream execution, response mapping,
  and completion notification when they participate;
- use `alt`, `opt`, `loop`, and parallel group visual regions for feature gates,
  cache hit/miss, retries, polling, asynchronous work, failures, and compensation;
- draw return messages and error propagation back through the same boundaries;
- keep enough vertical spacing and label wrapping to remain readable; when the
  full trace cannot fit legibly in one diagram, use one detailed primary sequence
  plus focused continuation sequences rather than omitting participants or
  interactions.

Before publishing, compare both diagrams against the execution bookmark tree.
Every material runtime phase and cross-service handoff in the tree must appear in
the Architecture Diagram and in the appropriate position in the Sequence Diagram.
If a diagram intentionally omits a secondary branch for readability, link to a
focused diagram that contains it. Also verify that every known component-specific
telemetry link appears on each applicable node and opens the intended query or
saved view rather than a generic telemetry landing page.

### Diagram type fidelity

Do not create a collection of generic cards and merely label it with a diagram
type. Each diagram must visually and semantically follow the conventions of that
diagram type. The viewer should recognize the diagram type without reading its
heading.

Every applicable diagram section must begin with the question it answers. Use
the following definitions and visual grammar.

#### 1. Architecture Diagram

**Question it answers:** What are the components and how do they interact?

Required visual grammar:

- show actors, gateways/front doors, services, modules, identity providers,
  planners/orchestrators, caches, queues, and data stores as distinct nodes;
- arrange nodes by architectural layer, boundary, ownership, or request
  direction rather than as an arbitrary grid;
- use directional connectors to show calls, dependencies, events, or data
  access;
- label important connectors with protocol, operation, or interaction;
- use containers/boundaries for repositories, services, trust zones, or
  deployment units where relevant;
- show fan-out/fan-in and external dependencies clearly;
- use conventional visual distinctions for people, services, databases, queues,
  and caches.

This is the primary structural picture and is mandatory. It must not be replaced
by a prose list of components.

#### 2. Sequence Diagram

**Question it answers:** What happens step-by-step during a request or operation?

Required visual grammar:

- place participants horizontally across the top;
- draw a vertical lifeline beneath every participant;
- order time from top to bottom;
- draw horizontal directional message arrows between lifelines;
- label each message with the operation, request, response, event, retry, cache
  lookup, or failure;
- distinguish calls from returns and synchronous from asynchronous interactions;
- use grouped alternatives/loops for conditions, retries, polling, cache hits,
  or failures when applicable;
- start with the initiating actor and end with the observable result.

Do not render a sequence diagram as a vertical flowchart of boxes. It is
mandatory and should show the most representative request, event, initialization,
or build-time interaction for the topic.

#### 3. Flowchart / Decision Tree

**Question it answers:** What decisions does the code or workflow make?

Required visual grammar:

- use a clear start and terminal/result nodes;
- use process rectangles for actions;
- use diamond-shaped nodes for decisions;
- label every outgoing decision edge, such as `Yes`/`No`, hit/miss, allowed/
  denied, success/failure, or feature enabled/disabled;
- show loops, retries, early returns, fallback paths, and error exits;
- keep arrow direction consistent and avoid ambiguous crossing lines;
- use a decision tree layout when mutually exclusive rules are the focus and a
  flowchart layout when procedural actions between decisions are important.

Use this for branching, caching, authorization, routing, retries, validation, or
complex logic. Include it whenever such decisions materially affect the topic.

#### 4. State Machine Diagram

**Question it answers:** What states can an object or process be in, and what
causes transitions?

Required visual grammar:

- use named state nodes, not action steps;
- include an explicit initial state and terminal states where they exist;
- draw directed transitions between states;
- label transitions with event, command, condition/guard, timeout, or failure;
- show self-transitions, retries, cancellation, pause/resume, and invalid or
  rejected transitions when relevant;
- visually distinguish successful, failed, paused, and terminal states.

Use this for jobs, deployments, long-running operations, resource lifecycle,
workflows, circuit breakers, sessions, or durable entities. Do not use a state
machine for a stateless request pipeline.

#### 5. Data Flow Diagram

**Question it answers:** How does data move and transform?

Required visual grammar:

- distinguish external entities, processes/transformations, and data stores;
- use directional arrows labeled with the actual data being carried, such as
  token/claims, request DTO, KQL, metadata, event, raw logs, cache entry, result,
  or error;
- show validation, enrichment, normalization, aggregation, filtering, rewriting,
  serialization, and persistence as processes when applicable;
- show where data is cached, queued, stored, read, or emitted;
- mark trust, service, repository, or region boundaries crossed by the data;
- distinguish control flow from data flow and omit control-only arrows unless
  needed for context;
- begin at the data source and end at each consumer/output.

This diagram is mandatory. It must focus on the payload and transformations, not
repeat the Architecture Diagram with unlabeled service arrows.

#### 6. Component Diagram

**Question it answers:** Who owns each responsibility inside the system or
selected service?

Required visual grammar:

- draw the selected system/service/container as a visible boundary;
- place its modules/components inside that boundary;
- give each component a concise responsibility;
- show provided/required interfaces or labeled dependencies where useful;
- show external dependencies outside the boundary;
- group components by layer or concern when that clarifies ownership;
- link components to their implementation, interface, registration, and tests
  when precise sources exist.

Use this to explain internal code organization, ownership, and responsibility.
Do not reduce it to a directory tree unless the directory structure genuinely
matches runtime component boundaries.

### Rendering quality

All six diagram types must be rendered as actual visual diagrams using
self-contained HTML/CSS/SVG. Text-only ASCII art and fenced source code are
examples of the desired semantics, not acceptable final rendering.

For every diagram:

- set SVG node colors with SVG properties such as `fill` and `stroke`; CSS
  `background` and `border` do not color SVG shapes and can leave them at the
  browser's default black;
- set SVG text colors explicitly and keep every node label at WCAG AA contrast
  against its actual rendered fill; never rely on inherited page text colors;
- visually inspect at least the Architecture and Sequence diagrams in a browser
  before publishing, and correct any black/default-filled, low-contrast, clipped,
  or unreadable nodes;
- size nodes and labels for comfortable reading without zooming;
- keep the primary reading direction obvious;
- use whitespace and alignment to communicate grouping;
- add arrowheads and connector labels;
- avoid overlapping nodes, labels, and connectors;
- provide a visible legend for colors, shapes, and line styles;
- preserve the required clickable source/bookmark behavior;
- include enough detail to teach the real system without turning the diagram
  into an unreadable source-code dump.

Then consider the remaining sections in the order below. Include an optional
section only when it adds distinct learning value. Omit inapplicable or
redundant optional sections rather than creating empty or speculative diagrams.

| Order | Section | Include when |
|---:|---|---|
| 1 | **Architecture Diagram** | **Always required.** |
| 2 | **Sequence Diagram** | **Always required.** |
| 3 | **Data Flow Diagram** | **Always required.** |
| 4 | **High-Level Architecture Diagram** | A newcomer needs an additional simplified overview distinct from the mandatory Architecture Diagram. |
| 5 | **Component Diagram** | Internal ownership, responsibilities, interfaces, or dependencies materially improve understanding. |
| 6 | **System Context Diagram (C4 Level 1)** | The system boundary, users, and external systems are relevant. |
| 7 | **Container Diagram (C4 Level 2)** | Deployable/runnable applications, services, jobs, databases, or repositories and their protocols must be distinguished. |
| 8 | **Component Diagram (C4 Level 3)** | The internal components of one selected container are important. Do not duplicate the generic Component Diagram. |
| 9 | **Code/Class Diagram (C4 Level 4)** | Concrete classes, interfaces, inheritance, composition, or key method ownership materially improve understanding. |
| 10 | **Activity Diagram** | A workflow has parallel work, joins, loops, responsibilities, or business activities. |
| 11 | **Flowchart / Decision Tree** | The topic contains meaningful procedural decisions, caching, routing, authorization, validation, retries, feature gates, or mutually exclusive rules. |
| 12 | **State Machine Diagram** | A durable entity or process has named states, guarded transitions, terminal states, or invalid transitions. |

Applicability rules:

- inspect the code and evidence before choosing diagram types;
- always create the mandatory Architecture, Sequence, and Data Flow diagrams;
- do not infer nonexistent containers, components, states, or transitions merely
  to fill the catalog;
- when two diagram types would be substantially identical, choose the one that
  most accurately represents the concept;
- use C4 levels only when their scope and abstraction level are respected;
- for a multi-repository topic, show repository ownership and boundaries in at
  least one applicable architecture/C4/component diagram;
- for recent changes, represent before/after behavior in the most suitable
  applicable diagram instead of creating a mandatory standalone section;
- include security, failures, limits, concurrency, ordering, and tests in the
  relevant diagrams when they materially affect the behavior;
- include a realistic concrete example in the most suitable flow, sequence,
  activity, decision, or state diagram when it improves comprehension.
- expose applicable `Example`, `Before / After`, `Hardening`, `Cross-repo`, and
  `Tests` views through the page navigation, even when their content is embedded
  in or cross-links to one of the ordered diagram sections.

### Diagram construction and links

Use normal HTML/CSS nodes and arrows so the file works offline without Mermaid.
Every visual node should contain:

- when the guide spans multiple repositories and multiple services, a visible
  first-line `[<Repository>-<Service>]` ownership prefix or badge on every node
  in every flow, including actors, sequence participants, processes, services,
  components, decisions, stores, caches, queues, states, failures, and terminal
  results; use the exact repository name and a concise stable service or
  deployable-component name, and keep this label readable by wrapping it onto a
  dedicated line rather than abbreviating away ownership context;
- a short title;
- one or more concise detail lines sufficient to understand its role;
- a visible type/status badge that agrees with the legend;
- a clickable source, documentation, test, historical version, or related
  bookmark link when one exists;
- a separately named `Telemetry` link when verified node-specific or correlated
  component-family telemetry is known;
- for Azure DevOps-hosted code, a separately named `Code` link immediately beside
  every `Telemetry` link, targeting that node's precise implementation or
  telemetry-emission range;
- a tooltip or visible source label when useful.

Clickable behavior:

- clicking a node with one primary reference opens that reference in a new tab,
  and the node also shows a visible named link such as `Code`, `Docs`, `Tests`,
  or `Before`; do not rely on an invisible whole-node click target as the only
  indication that evidence exists;
- when a node has several useful references, provide individually named links
  inside the node, such as `Implementation`, `Interface`, `Tests`, `Telemetry`,
  `Before`, or `Related bookmark`;
- keep `Telemetry` separate from implementation and test links; it opens the
  exact query or saved view for that node and must not become the node's primary
  click target when doing so would hide other references;
- render `Code` and `Telemetry` as an explicit adjacent pair. The node itself may
  remain clickable to the same source, but that does not replace the visible
  `Code` label;
- internal links to another diagram or bookmark-tree destination are allowed;
- use `target="_blank" rel="noopener noreferrer"` for external and local-file
  links so the overview remains open;
- never invent a link or attach an unrelated source merely to make a node
  clickable;
- when a node has no verified source in the investigated repositories, say so
  visibly inside the node, for example `Code unavailable in investigated
  repositories`, instead of leaving an unlabeled non-clickable rectangle;
- visually distinguish clickable nodes from explanatory nodes without links;
- diagrams may link directly to source, another diagram, or a related execution
  bookmark, but diagram sections must not define the bookmark hierarchy.

Do not overload prose outside the diagrams. Put operational detail inside the
nodes while keeping labels readable.

## Bookmark hierarchy

The overview HTML and the bookmark tree serve different purposes:

- the **overview HTML** is the design and learning story, organized by diagrams
  and applicable learning views;
- the **bookmark tree after the overview link** is a detailed executable trace,
  organized by the order in which code runs.

Never create bookmark folders named after HTML sections or diagram types merely
because those sections exist. Do not create `Architecture Diagram`, `Sequence
Diagram`, `Data Flow Diagram`, `Example`, `Before and After`, `Hardening`,
`Cross-repo`, or `Tests` folders unless one of those names is literally a phase
in the executed system.

Create a hierarchy shaped like the actual execution:

```text
Imported
  <Topic>
    00 - Open <Topic> Overview
    01 - Request Entry
      01. Client constructs request
      02. Public endpoint receives request
      03. Request model is parsed
    02 - Authentication and Authorization
      01. Token is validated
      02. Access policy is evaluated
    03 - Orchestration
      01. Handler builds execution context
      02. Planner selects downstream path
    04 - Downstream Service Handoff
      01. Client sends downstream request
      02. Downstream endpoint accepts request
      03. Downstream orchestrator processes request
    05 - Data Access and Transformation
      01. Repository or provider loads data
      02. Data is transformed
      03. Result is assembled
    06 - Response Path
      01. Downstream response is mapped
      02. Public response is returned
```

Adapt phase names to the real feature. The example names are not a required
template.

### Execution-order rules

- keep `00 - Open <Topic> Overview` as the first item;
- every later bookmark should normally point to a precise executable source
  location: endpoint, middleware, handler, validator, service method,
  orchestrator, client call, message handler, grain, repository/provider,
  transformation, persistence operation, or response mapper;
- order bookmarks by runtime execution, not by repository, service, source-file
  path, diagram section, or research order;
- when execution crosses repositories or services, interleave those bookmarks
  at the exact handoff point instead of grouping all links by repository;
- include the caller immediately before the callee so a reader can follow each
  boundary crossing;
- use numbered action-oriented names that explain what executes;
- when the execution trace spans multiple repositories and multiple services,
  prefix every executable bookmark action with `[<Repository>-<Service>]` after
  its sequence number, for example
  `04. [Azure-Kusto-WebUX-Query Client] Client sends query request`; use the
  exact repository name and a concise, stable service or deployable-component
  name so every cross-boundary step carries its ownership context;
- omit the repository-service prefix for single-repository or single-service
  guides, where it would add noise without disambiguating ownership;
- create folders only for meaningful runtime phases, boundary crossings, or
  branches that improve navigation;
- preserve nested execution order inside every folder;
- include important unchanged steps so PR/change guides remain a complete path;
  add `[New]`, `[Changed]`, `[Removed]`, or `[Unchanged]` to bookmark names in PR
  mode when useful;
- represent a decision with nested branch folders such as `Allowed`/`Denied`,
  `Hit`/`Miss`, or `Success`/`Failure`, ordered as the code evaluates them;
- label asynchronous or parallel branches explicitly, such as `[Async] Publish
  event` or `[Parallel] Fan-out to regions`, rather than pretending they are
  synchronous;
- place callbacks, polling, retries, fallback, and response unwinding at their
  actual positions in the trace;
- omit declarations, DTOs, tests, documentation, and historical code from the
  execution tree unless they execute or directly define a runtime step. They can
  still be linked from diagram nodes and learning views;
- keep telemetry queries and dashboards on the applicable diagram nodes or
  learning views rather than adding them to the runtime execution tree, unless
  querying or emitting that telemetry is itself part of the executed flow;
- avoid duplicate bookmarks unless the same code genuinely executes at multiple
  distinct points; distinguish repeated execution in the bookmark names.

### Relationship between diagrams and execution bookmarks

The diagrams tell the design story and may summarize, branch, or compare the
flow. The bookmark tree is the detailed source-level trace. They should
cross-reference each other without becoming structurally identical:

- make diagram nodes clickable to their most relevant precise source;
- when useful, link diagram nodes to the same precise sources represented by the
  related execution bookmarks;
- a single diagram node may correspond to several consecutive execution
  bookmarks;
- a single execution bookmark may be referenced by several diagrams;
- do not duplicate a source bookmark solely because it appears in multiple
  diagrams.

## Publisher manifest

Write `<topic-slug>-bookmarks.json`:

```json
{
  "title": "Patterns - Cross-Resource Flow",
  "overviewPath": "C:\\Users\\user\\OneDrive - Microsoft\\Documents\\Learning Bookmarks\\patterns-cross-resource-flow\\patterns-cross-resource-flow-overview.html",
  "folders": [
    {
      "name": "01 - Request Entry",
      "links": [
        {
          "name": "01. Endpoint receives request (Public API)",
          "url": "https://example/source-link"
        },
        {
          "name": "02. Handler validates request (Public API)",
          "url": "https://example/validation-source-link"
        }
      ],
      "folders": []
    },
    {
      "name": "02 - Downstream Handoff",
      "links": [
        {
          "name": "01. Client sends request (Service A)",
          "url": "https://example/client-source-link"
        },
        {
          "name": "02. Endpoint accepts request (Service B)",
          "url": "https://example/downstream-source-link"
        }
      ],
      "folders": []
    },
    {
      "name": "03 - Response Path",
      "links": [
        {
          "name": "01. Result is mapped and returned (Public API)",
          "url": "https://example/response-source-link"
        }
      ],
      "folders": []
    }
  ]
}
```

Top-level `links` are optional. The publisher always inserts the overview link first.

## Publish

Always generate a browser-compatible import file. Browser process state does not
matter because the publisher must not modify Chrome or Edge profile files.

Never directly edit, replace, restore, or reorganize a Chromium `Bookmarks`
file, even when the browser is closed and a checksum can be recalculated.
Favorites/Bookmarks Sync tracks parent relationships outside that JSON file.
Direct file changes can therefore cause unrelated, previously organized folders
to be flattened or restored from stale sync state. Moving, grouping, replacing,
or restoring favorites must be done through the browser's Favorites/Bookmarks
Manager or the companion's official `chrome.bookmarks` API so sync metadata is
updated.

### One-time Edge companion installation

Run:

```powershell
& "<skill-directory>\scripts\Install-EdgeFavoritesCompanion.ps1"
```

The helper opens `edge://extensions` and the bundled `edge-companion` folder.
Enable Developer mode, select **Load unpacked**, choose that folder, and verify
the stable ID `bcnnjcbahmgdcieaelpellgemkkgjgcg`. This is an explicit one-time
unpacked installation; the helper never modifies policy or forces installation.

After installation, Edge publication can be automatic:

```powershell
& "<skill-directory>\scripts\Publish-LearningBookmarks.ps1" `
  -ManifestPath "<topic-folder>\<topic-slug>-bookmarks.json" `
  -Browser Edge `
  -Mode EdgeApi `
  -DestinationPath "Favorites bar","Imported"
```

The destination must already exist and every segment must resolve exactly once.
`EdgeApi` removes only same-named topic folders at that destination, then creates
the complete topic tree with the overview first and browser-managed IDs. Never
report automatic publication as successful unless the bridge returns `ok: true`.

Import fallback remains available:

```powershell
& "<skill-directory>\scripts\Publish-LearningBookmarks.ps1" `
  -ManifestPath "<topic-folder>\<topic-slug>-bookmarks.json" `
  -Browser Both `
  -Mode Import
```

Use `-Mode EdgeApi -Browser Edge` when the companion is installed. Use
`-Mode Import` for Chrome, for both browsers, or whenever the companion is not
installed. The publisher always retains the generated import file.

Modes:

- `Auto`: safely falls back to import HTML because direct profile editing is
  disabled.
- `Direct`: fails without modifying browser data. It remains only for backward
  compatibility with existing invocations.
- `Import`: only creates browser-compatible Netscape bookmark HTML.
- `EdgeApi`: requires `-Browser Edge`, builds an `upsertManifestTopic` command,
  invokes the authenticated loopback bridge, and succeeds only after a validated
  extension result.

Browser targets:

- `Both`: Chrome and Edge; this is the default.
- `Chrome`: Chrome only.
- `Edge`: Microsoft Edge only.

Before every publication, the publisher also updates the overview HTML's
embedded bookmark tree from this manifest.

### Safe folder restoration

To replace one exact existing Edge folder's children from a known-good Chromium
backup without touching the profile file:

```powershell
& "<skill-directory>\scripts\Restore-EdgeFavoritesFolder.ps1" `
  -BackupPath "<read-only Bookmarks backup>" `
  -FolderPath "Kusto","Engine","Cache" `
  -OutputCommandPath "<durable-folder>\cache-restore-command.json" `
  -Apply
```

The script reads `roots.bookmark_bar`, fails on missing or ambiguous path
segments, converts only the selected folder's complete children, and sends a
`replaceFolderChildren` command through the same companion. Omit `-Apply` to
generate and inspect the command only. Never copy the backup over the browser
profile. Use this companion for all future automated favorite movement,
grouping, and restoration.

When organized topic folders are duplicated under `Imported`, use the
companion's narrowly scoped `removeNamedFolders` command after computing the
exact intersection. Never replace all `Imported` children to remove duplicates.

## Version control for this skill

This skill's durable installation directory is also its Git working copy. When
the user asks to change this skill or any bundled script/template:

1. Load this skill before editing it.
2. Modify only the skill files needed for the request.
3. Validate affected scripts, templates, and generated behavior.
4. Inspect the Git diff and ensure it contains no generated learning artifacts,
   temporary files, credentials, browser profile data, or unrelated user files.
5. Commit the completed skill change with a concise descriptive message.
6. Push the current branch to the configured `origin` remote.
7. Do not report the skill update as complete until the push succeeds.
8. If authentication, connectivity, conflicts, or branch protection prevents
   the push, preserve the local commit and tell the user exactly what remains
   unpushed.

Normal `/learn-with-bookmarks` runs create learning artifacts but do not modify
or commit the skill repository. Commit and push only when the skill
implementation, instructions, scripts, or templates change.

Never terminate Chrome or Edge. Direct publication is permanently blocked.

Import mode intentionally emits only the topic folder. Chrome or Edge creates the
top-level `Imported` folder during import. Tell the user to use the applicable
bookmark manager:

```text
Chrome Bookmark Manager -> three-dot menu -> Import bookmarks
Edge Favorites -> three-dot menu -> Import favorites
```

## Completion response

Lead with the result and provide:

- overview HTML path;
- bookmark manifest path;
- import path for Chrome and Edge;
- for EdgeApi, the destination and validated companion result; otherwise, a
  reminder that import must be completed through the browser UI;
- the invocation for next time:

```text
/learn-with-bookmarks <topic>
```

Do not claim that restarting a browser imports the file automatically, and do
not claim EdgeApi success without a successful structured bridge result.
