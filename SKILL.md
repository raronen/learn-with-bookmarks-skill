---
name: learn-with-bookmarks
description: Investigate and teach a technical topic across one or more repositories, then create a durable local HTML learning guide with a collapsed bookmark tree followed by applicable, detailed, color-coded architecture, C4, component, sequence, activity, flow, decision, state, or code diagrams, and publish a structured bookmark folder under Chrome's top-level Imported folder. Use when the user says they want to learn, understand, trace, or get an overview of a feature, flow, architecture, incident, or recent code changes and wants diagrams plus source links/bookmarks.
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
5. Add applicable Example, Before/After, Hardening, Cross-repo, and Tests
   learning views with prominent same-page navigation.
6. Create categorized sub-bookmarks matching the guide's sections and flow.
7. Publish the topic folder under Chrome's top-level `Imported` folder when Chrome is closed.
8. If direct publication is unavailable, create an import-ready HTML file whose contents Chrome places under `Imported`.
9. Keep all generated artifacts in durable storage, never session state or a temporary directory.

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

The JSON file is the publisher manifest, not a Chrome-import format. Chrome imports
Netscape bookmark HTML.

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
     commits, tests, and before/after behavior;
   - an instruction not to modify code.
5. Run independent repository research in parallel.
6. Wait for and aggregate all child reports before generating artifacts.
7. For the current repository, investigate inline rather than creating a redundant
   child session.

Use the `orchestrate` skill's cross-repo research workflow when available.

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
- relevant historical implementation for "before" nodes.

For recent changes:

1. Identify the author and commits.
2. Separate merge commits from implementation commits.
3. Compare parent/current versions for removed behavior.
4. Explain adjacent hardening commits when they materially affect the same flow.
5. Clearly distinguish observed code from inference.

## Source-link rules

Prefer permanent web links that the user can open outside the local checkout.

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
- the tree order and names exactly match the generated Chrome bookmarks;
- the tree remains usable independently of Chrome's bookmark popup.

The generated tree uses native `<details>` and `<summary>` elements. Add the
`open` attribute only to the topic-root `<details>` element. Never add it to
nested folders. Links must use:

```html
target="_blank" rel="noopener noreferrer"
```

Do not manually duplicate the manifest into the tree. Generate the manifest
first, then run the publisher; it replaces the marker block with the canonical
tree. This prevents the HTML tree and Chrome bookmark hierarchy from drifting.

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

After the collapsed bookmark tree and navigation, consider the following diagram
sections in this exact order. Include a section only when it adds distinct
learning value for the investigated topic. Omit inapplicable or redundant
sections rather than creating empty or speculative diagrams.

| Order | Section | Include when |
|---:|---|---|
| 1 | **Architecture Diagram** | Several architectural concerns or layers must be shown together, including boundaries, data movement, deployment, or cross-cutting concerns. |
| 2 | **High-Level Architecture Diagram** | A newcomer needs a simplified overview before detailed diagrams. Prefer this over the generic Architecture Diagram when both would communicate the same facts. |
| 3 | **Component Diagram** | The important learning unit is the dependency or collaboration structure between modules/components and a C4 hierarchy is unnecessary. |
| 4 | **System Context Diagram (C4 Level 1)** | The system boundary, users, and external systems are relevant. |
| 5 | **Container Diagram (C4 Level 2)** | Deployable/runnable applications, services, jobs, databases, or repositories and their protocols must be distinguished. |
| 6 | **Component Diagram (C4 Level 3)** | The internal components of one selected container are important. Do not duplicate the generic Component Diagram. |
| 7 | **Code/Class Diagram (C4 Level 4)** | Concrete classes, interfaces, inheritance, composition, or key method ownership materially improve understanding. |
| 8 | **Sequence Diagram** | Ordering across participants, synchronous/asynchronous calls, replies, retries, or temporal behavior matters. |
| 9 | **Activity Diagram** | A workflow has parallel work, joins, loops, responsibilities, or business activities. |
| 10 | **Flowchart** | A procedural path, request pipeline, transformation chain, before/after flow, or concrete walkthrough is central. |
| 11 | **Decision Tree** | The topic contains meaningful mutually exclusive rules, routing, authorization, feature gates, or troubleshooting choices. |
| 12 | **State Machine Diagram** | A durable entity or process has named states, guarded transitions, terminal states, or invalid transitions. |

Applicability rules:

- inspect the code and evidence before choosing diagram types;
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

- a short title;
- one or more concise detail lines sufficient to understand its role;
- a visible type/status badge that agrees with the legend;
- a clickable source, documentation, test, historical version, or related
  bookmark link when one exists;
- a tooltip or visible source label when useful.

Clickable behavior:

- clicking a node with one primary reference opens that reference in a new tab;
- when a node has several useful references, provide individually named links
  inside the node, such as `Implementation`, `Interface`, `Tests`, `Before`, or
  `Related bookmark`;
- internal links to another diagram or bookmark-tree destination are allowed;
- use `target="_blank" rel="noopener noreferrer"` for external and local-file
  links so the overview remains open;
- never invent a link or attach an unrelated source merely to make a node
  clickable;
- visually distinguish clickable nodes from explanatory nodes without links;
- bookmarks for a diagram section must appear in the same top-to-bottom or
  left-to-right order as the diagram.

Do not overload prose outside the diagrams. Put operational detail inside the
nodes while keeping labels readable.

## Bookmark hierarchy

Create this shape:

```text
Imported
  <Topic>
    00 - Open <Topic> Overview
    01 - Architecture Diagram
      01. ...
      02. ...
    02 - High-Level Architecture Diagram
      01. ...
    03 - Component Diagram
      01. ...
    04 - System Context Diagram (C4 Level 1)
      01. ...
    05 - Container Diagram (C4 Level 2)
      01. ...
    06 - Component Diagram (C4 Level 3)
    07 - Code/Class Diagram (C4 Level 4)
    08 - Sequence Diagram
    09 - Activity Diagram
    10 - Flowchart
    11 - Decision Tree
    12 - State Machine Diagram
```

Create folders only for diagram sections that appear in the overview. Preserve
the relative order above, renumber included folders contiguously, retain numeric
prefixes, and keep the overview first. Add nested folders such as `Tests`,
`Historical implementation`, or repository names only where they improve
navigation. Bookmark ordering must match each diagram's reading order.

When an applicable learning view has substantial unique references, add a
matching bookmark folder after the diagram folders:

```text
90 - Example
91 - Before and After
92 - Hardening
93 - Cross-repo
94 - Tests
```

Include only applicable folders and preserve their relative order. Do not create
a `Bookmarks` folder because the embedded tree already represents the complete
bookmark hierarchy.

Avoid duplicate links unless the same source genuinely proves two different concepts.

## Publisher manifest

Write `<topic-slug>-bookmarks.json`:

```json
{
  "title": "Patterns - Cross-Resource Flow",
  "overviewPath": "C:\\Users\\user\\OneDrive - Microsoft\\Documents\\Learning Bookmarks\\patterns-cross-resource-flow\\patterns-cross-resource-flow-overview.html",
  "folders": [
    {
      "name": "01 - High-Level Architecture Diagram",
      "links": [
        {
          "name": "01. API entry point",
          "url": "https://example/source-link"
        }
      ],
      "folders": []
    }
  ]
}
```

Top-level `links` are optional. The publisher always inserts the overview link first.

## Publish

Before running the publisher, check whether any Chrome process is running.

1. If Chrome is closed, run `-Mode Direct`.
2. If Chrome is running and the interaction supports questions, ask the user to
   choose between:
   - closing Chrome completely so direct publication can proceed; or
   - keeping Chrome open and generating the manual import file.
3. When the user chooses direct publication, wait for their confirmation, check
   again that no Chrome process remains, and then run `-Mode Direct`. Do not fall
   back to import without telling them.
4. When questions are unavailable or the user chooses to keep Chrome open, run
   `-Mode Import` and clearly state that restarting Chrome does not import the
   file automatically.

Run the bundled publisher:

```powershell
& "<skill-directory>\scripts\Publish-LearningBookmarks.ps1" `
  -ManifestPath "<topic-folder>\<topic-slug>-bookmarks.json" `
  -Mode Direct
```

Use `-Mode Import` instead only when the user chose the fallback or questions are
unavailable.

Modes:

- `Auto`: directly updates Chrome if it is closed; otherwise creates import HTML.
- `Direct`: requires Chrome to be closed; backs up and updates the Default profile.
- `Import`: only creates Netscape bookmark HTML.

Direct mode:

- targets Chrome's `Default` profile unless overridden;
- creates a timestamped backup;
- creates or reuses top-level `Imported` on the bookmarks bar;
- replaces the same-named topic folder, making reruns idempotent;
- recalculates Chromium's bookmark checksum;
- writes atomically;
- verifies the resulting JSON and checksum.

Before either direct or import publication, the publisher also updates the
overview HTML's embedded bookmark tree from this manifest.

## Version control for this skill

This skill's durable installation directory is also its Git working copy. When
the user asks to change this skill or any bundled script/template:

1. Load this skill before editing it.
2. Modify only the skill files needed for the request.
3. Validate affected scripts, templates, and generated behavior.
4. Inspect the Git diff and ensure it contains no generated learning artifacts,
   temporary files, credentials, Chrome profile data, or unrelated user files.
5. Commit the completed skill change with a concise descriptive message.
6. Push the current branch to the configured `origin` remote.
7. Do not report the skill update as complete until the push succeeds.
8. If authentication, connectivity, conflicts, or branch protection prevents
   the push, preserve the local commit and tell the user exactly what remains
   unpushed.

Normal `/learn-with-bookmarks` runs create learning artifacts but do not modify
or commit the skill repository. Commit and push only when the skill
implementation, instructions, scripts, or templates change.

Never terminate Chrome. Ask the user to close it for direct publication; use the
fallback only when they choose not to close it or interactive confirmation is
unavailable.

Import mode intentionally emits only the topic folder. Chrome itself creates the
top-level `Imported` folder during import. Tell the user to use:

```text
Chrome Bookmark Manager -> three-dot menu -> Import bookmarks
```

## Completion response

Lead with the result and provide:

- overview HTML path;
- bookmark manifest path;
- whether direct publication succeeded;
- fallback import path when generated;
- the invocation for next time:

```text
/learn-with-bookmarks <topic>
```

Do not claim direct publication succeeded unless the publisher reports success.
