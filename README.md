# Learn with bookmarks

A persistent Copilot skill that investigates technical topics across one or more
repositories and produces:

- a durable, self-contained HTML learning guide;
- an expanded top-level bookmark tree with collapsed nested folders;
- a detailed bookmark tree ordered by the code's actual execution path across
  repositories and services, independent of the HTML diagram sections;
- mandatory color-coded Architecture, Sequence, and Data Flow diagrams;
- architecture and sequence diagrams that preserve the full investigated
  end-to-end detail: participating services and internal components, concrete
  responsibilities, labeled operations and payloads, boundaries, parallel work,
  retries, failures, callbacks, and rollback paths;
- applicable C4, component, activity, flow, decision, state, and code diagrams;
- strict visual grammar so sequence diagrams use lifelines/messages, decisions
  use diamonds/labeled branches, state machines use transitions, and data-flow
  diagrams show entities/processes/stores with labeled payload movement;
- ARM MCP investigation and management-plane end-to-end views for features
  invoked through Azure Resource Manager;
- source-linked Example, Before/After, Hardening, Cross-repo, and Tests views;
- verified component-specific or correlated component-family telemetry links
  that open the exact query or saved view directly from every applicable
  diagram node, with exploratory row results capped at 10 by default;
- a PR-learning mode that resolves Azure DevOps PRs, analyzes base-versus-PR
  behavior, and links directly to precise ranges in the PR Files experience;
- structured Chrome and Microsoft Edge bookmark folders under `Imported`.

Invoke it with:

```text
/learn-with-bookmarks <topic or question>
```

## Installation

Place or clone this repository at:

```text
C:\Users\<user>\.copilot\skills\learn-with-bookmarks
```

## Versioning policy

`SKILL.md` requires every validated change to this skill's implementation,
instructions, scripts, or templates to be committed and pushed to `origin`.
Normal learning-guide generation does not create commits.
