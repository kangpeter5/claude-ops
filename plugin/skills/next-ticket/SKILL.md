---
name: next-ticket
description: Claim the oldest claude-ready Linear issue for a team and hand it to /implement-ticket. Used by the hourly worker scheduled task. Exits quietly when there is nothing to do.
argument-hint: "<LINEAR TEAM KEY>"
disable-model-invocation: true
allowed-tools: Read, Bash(git *), Bash(gh *), mcp__Linear__*
effort: medium
---

# /next-ticket

Team key: `$0`. If empty, read `team:` from the repository `CLAUDE.md` under `## Linear`. If still empty, stop.

## Steps

1. **Find candidates.** List issues in the team with label `claude-ready` and without labels `claude-in-progress`, `claude-pr-open`, `claude-blocked`, excluding completed and canceled states. Order by priority (urgent first), then by creation date (oldest first).
2. **Nothing to do?** If the list is empty, print `next-ticket: no claude-ready issues for <TEAM>` and stop. Do not create anything, do not post anywhere.
3. **Check for an existing branch.** For the top candidate, if a remote branch `claude/<KEY>-*` already exists, skip it and comment on the issue once: "A branch already exists for this issue; remove it or the `claude-ready` label." Try the next candidate.
4. **Claim.** Add the label `claude-in-progress` (create it if missing). Comment on the issue:

   ```
   Claimed by claude-ops worker. Session: <link to this session if available, else the run timestamp>.
   Branch: claude/<KEY>-<slug>
   ```

   Do not remove `claude-ready`; it stays as the human's intent marker.
5. **Hand off.** Invoke `/implement-ticket <KEY>` (as a plugin: `/delivery-loop:implement-ticket <KEY>`).

## Concurrency note

One worker task per repository, running hourly, is the intended setup. The `claude-in-progress` label is the claim; a second worker seeing it moves on. If two teams map to the same repository, run one worker per team and keep the branch-existence check in step 3.
