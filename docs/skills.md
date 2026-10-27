# Skills and subagents

All skills set `disable-model-invocation: true`: they run when a person types them or a scheduled-task prompt names them, never because Claude decided to. When installed as a plugin they are namespaced `/delivery-loop:<name>`; vendored by the installer they are `/<name>`.

## /intake \<notion-url|-\> \<slack-url|-\> --team KEY [--project NAME]

Reads the PRD and the thread through the `prd-analyst` subagent, which returns structured YAML (tickets, acceptance criteria, estimates, decisions needed, overlaps with existing issues). Sanity-checks it, then the `ticket-writer` subagent creates issues in **Triage** with `agent-drafted`, plus one `Decisions needed: <PRD>` issue that blocks the tickets it affects. Replies in the Slack thread with the list.

It never sets any other state and never adds `claude-ready`.

## /next-ticket KEY

Finds the oldest `claude-ready` issue for the team that has no `claude-in-progress`, `claude-pr-open` or `claude-blocked` label and no existing `claude/<KEY>-*` branch. Claims it with the label and a comment, then invokes `/implement-ticket`. Exits quietly if nothing qualifies.

## /implement-ticket KEY

1. Understand: fetch the issue, check blockers, restate acceptance criteria. Anything untestable → `claude-blocked` with a question.
2. Implement on `claude/<KEY>-<slug>` with tests for every criterion. Test and lint green before each commit.
3. Draft PR titled `<KEY>: <title>` with the criteria checklist and `Closes` link.
4. Self-review loop, max 3 rounds: `reviewer` (fresh context, JSON findings) → `pr-responder` (fix, test, commit `address self-review round N`, push) → PR comment with the round's findings. High findings left after round 3 → `claude-blocked`, PR stays draft.
5. `gh pr ready`, request reviewers, `claude-pr-open`, stop.

## /address-review [pr]

Fetches unresolved review threads and failing checks, delegates fixes to `pr-responder`, replies on each thread with the commit SHA. Never resolves threads, never force-pushes, never marks a draft ready.

## /release \<pr\>

Confirms the PR merged, posts a deploy checklist comment (migrations, flags, config, rollback, what to watch), writes a one-paragraph release note on the Linear issue, moves it to Done, posts to the originating Slack thread or the release channel. Never triggers a deploy.

## Subagents

| Agent | Tools | Job |
|---|---|---|
| `prd-analyst` | Read, Grep, Glob, Notion, Slack, Linear read tools | PRD + thread → structured YAML. Never writes |
| `ticket-writer` | Linear only | YAML → issues in Triage with the fixed description template |
| `reviewer` | Read, Grep, Glob, Bash; no Edit/Write, no MCP | Diff + acceptance criteria → JSON findings with severity, file, line, failure scenario |
| `pr-responder` | Read, Edit, Write, Grep, Glob, Bash; no MCP | Findings or threads → fixes, tests, commit, push, replies |

Each file is under `plugin/agents/`. The tool allowlists are the point; widen them only with a reason.
