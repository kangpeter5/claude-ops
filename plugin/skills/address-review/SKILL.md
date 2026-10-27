---
name: address-review
description: Address unresolved human review comments and failing checks on the current PR. Fixes, tests, commits, pushes, and replies on each thread. Never resolves threads, never force-pushes, never merges.
argument-hint: "[pr-number]"
disable-model-invocation: true
allowed-tools: Agent, Read, Edit, Write, Grep, Glob, Bash
effort: high
---

# /address-review

PR: `$0`. If empty, detect it from the current branch with `gh pr view --json number`.

## Steps

1. Fetch unresolved review threads and the latest check-run failures:
   - `gh pr view <n> --json reviews,comments,statusCheckRollup`
   - `gh api graphql` for `reviewThreads(first: 100) { nodes { isResolved comments { nodes { body path line author { login } } } } }`
   - For failed checks, `gh run view <id> --log-failed` when it is a GitHub Actions check; otherwise read the check's details URL.
2. Group threads by file. For each, decide: fix, won't fix with reason, or needs a decision.
3. Delegate to the `pr-responder` subagent (`delivery-loop:pr-responder` as a plugin) with the grouped threads and the failing-check output. It fixes, runs tests, commits `<KEY>: address review comments`, pushes, and replies on each thread with the commit SHA.
4. If it returns `blocked` items, post one PR comment titled "Needs a decision" listing them, and stop.
5. Summarize to the user: fixed, won't fix, blocked, and the commit SHA.

## Never

- Resolve a review thread. The reviewer resolves.
- Force-push, rebase onto a different base, or change the PR base.
- Dismiss a review or mark the PR ready if it was a draft.
