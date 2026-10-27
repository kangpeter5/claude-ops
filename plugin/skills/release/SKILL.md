---
name: release
description: After a PR merges, run the deploy checklist, write a release note, move the Linear issue to Done, and post to the originating Slack thread. Never deploys; a human approves the production environment.
argument-hint: "<pr-number>"
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *), mcp__Linear__*, mcp__Slack__*
effort: medium
---

# /release

PR: `$0`. Required. Read `CLAUDE.md` for the Linear team, the Slack channel for release notes, and anything under `## Deploy`.

## Steps

1. **Confirm merged.** `gh pr view <n> --json mergedAt,mergeCommit,title,body,labels,files`. If not merged, stop.
2. **Find the issue.** Parse the Linear key from the PR title (`<KEY>: ...`) or body. Fetch it.
3. **Deploy checklist.** Inspect the merged diff and answer each line; post the result as a PR comment:

   ```
   ### Deploy checklist (claude-ops)
   - Migrations: none | <files> (reversible: yes/no, rollback: <how>)
   - Feature flags: none | <flag names and default state>
   - Config or env changes: none | <keys>
   - External API or contract changes: none | <what>
   - Data backfill needed: no | <what>
   - Rollback: revert <merge sha> | <specific steps>
   - Watch after deploy: <metrics, logs, dashboards named in CLAUDE.md or the PR>
   Production deploy still requires a human approval in CD.
   ```

4. **Release note.** One paragraph, user-facing, no file names. Post it as a comment on the Linear issue and, if `CLAUDE.md` names a changelog file, append it there via a new branch and a small PR titled `docs: changelog for <KEY>`. Do not commit to the default branch.
5. **Linear.** Move the issue to the team's Done state. Remove `claude-pr-open`. Comment: "Merged in <PR url> (<merge sha>). Release note posted."
6. **Slack.** Find the originating thread: the issue's Sources section or its attachments. If found, reply there; otherwise post to the release channel from `CLAUDE.md`:

   ```
   Shipped <KEY> <title>: <release note>
   PR: <url> · Rollback: revert <sha> · Watch: <one line>
   ```

7. Stop. Do not trigger any deploy, workflow, or release.
