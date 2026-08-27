# Learn with bookmarks

A persistent Copilot skill that investigates technical topics across one or more
repositories and produces:

- a durable, self-contained HTML learning guide;
- a beginner-first `Start here` foundation that explains the product, problem,
  system context, happy path, terminology, and source-of-truth boundaries before
  implementation details;
- plain-English first-use definitions, a consistent concrete example or analogy,
  progressive disclosure, and `How to read it` guidance for every diagram so a
  new joiner can learn without prior domain or repository knowledge;
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
- visibly labeled `Code`, `Docs`, or other evidence links on diagram nodes,
  with explicit evidence-gap labels instead of ambiguous unlinked rectangles;
- verified runtime-place-specific telemetry links that open a genuinely narrowed
  query or saved view from every applicable diagram node, with exploratory row
  results capped at 10 by default and an adjacent node-specific `Code`
  implementation link;
- a PR-learning mode that resolves Azure DevOps PRs, analyzes base-versus-PR
  behavior, and links directly to precise ranges in the PR Files experience;
- a structured Chrome and Microsoft Edge import file for safe browser import;
- optional automatic Microsoft Edge publication through the bundled companion
  extension and Edge's official `chrome.bookmarks` API.

The publisher intentionally never edits Chromium `Bookmarks` profile files.
Direct JSON writes bypass sync metadata and can flatten unrelated favorites when
sync restores stale parent relationships. Publication, movement, grouping, and
restoration must use the Edge companion API or the browser's import/manager UI.

## One-time Edge companion installation

```powershell
& ".\scripts\Install-EdgeFavoritesCompanion.ps1"
```

In `edge://extensions`, enable Developer mode, choose **Load unpacked**, and
select `edge-companion`. Verify extension ID
`bcnnjcbahmgdcieaelpellgemkkgjgcg`. The helper only opens the page and folder;
it does not force-install or set policy.

After installation, publish automatically:

```powershell
& ".\scripts\Publish-LearningBookmarks.ps1" `
  -ManifestPath "<manifest.json>" `
  -Mode EdgeApi `
  -Browser Edge `
  -DestinationPath "Favorites bar","Imported"
```

The loopback bridge supplies one command with a random token and reports the
extension's structured result. Do not claim success unless that result succeeds.
If the companion is unavailable, use `-Mode Import` and import the generated
HTML through Edge or Chrome.

To restore only one folder's children from a read-only Chromium backup:

```powershell
& ".\scripts\Restore-EdgeFavoritesFolder.ps1" `
  -BackupPath "<Bookmarks backup>" `
  -FolderPath "Kusto","Engine","Cache" `
  -OutputCommandPath ".\cache-restore-command.json" `
  -Apply
```

This reads the backup but never edits or replaces any browser profile file.

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
