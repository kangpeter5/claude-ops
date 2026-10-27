# Getting started

About 15 minutes for the first repository, under 10 for each one after.

## Prerequisites

- A claude.ai plan with cloud sessions and scheduled tasks: Pro, Max, Team or Enterprise. ([Scheduled tasks docs](https://code.claude.com/docs/en/routines))
- GitHub connected to Claude at [claude.ai/code](https://claude.ai/code) and the [Claude GitHub App](https://github.com/apps/claude) installed on the target repository. GitHub event triggers need the app.
- Linear connected at [claude.ai/customize/connectors](https://claude.ai/customize/connectors). Notion and Slack if you use `/intake` and `/release`.
- Branch protection on the default branch with at least one required review, and a production environment with a required approver in whatever runs your deploys.

## 1. Install into the repository

From the repo root, on a new branch:

```bash
curl -fsSL https://raw.githubusercontent.com/kangpeter5/claude-ops/main/scripts/install.sh | bash -s -- --ref v0.1.0
```

This writes `.claude/skills/*`, `.claude/agents/*`, `.claude/hooks/claude-ops/guard.sh`, `.claude/claude-ops.lock`, and creates `CLAUDE.md` and `.claude/settings.json` if they don't exist. If they do exist, it prints what to merge.

## 2. Fill in CLAUDE.md

Open `CLAUDE.md` and replace every `<placeholder>`. The three things the skills cannot work without:

- the **test command**
- `team: <KEY>` under `## Linear`
- the **sensitive paths** list, which makes the reviewer treat those changes as high severity

Commit and open a PR. Merge it like any other change.

## 3. Create the Linear labels

Create these labels in the team: `agent-drafted`, `claude-ready`, `claude-in-progress`, `claude-pr-open`, `claude-blocked`. The skills create missing ones, but doing it by hand lets you pick colors and avoids a permission prompt on the first run.

## 4. Try it locally first

```bash
claude
> /implement-ticket <an existing small ticket key>
```

Watch it branch, implement, open a draft PR, and run the self-review loop. If the first thing it does is ask for a test command, go back to step 2.

Also confirm the guard: ask Claude to run `gh pr merge 1`. It must be denied.

## 5. Create the scheduled tasks

At [claude.ai/code/routines](https://claude.ai/code/routines), create three tasks for the repository. The prompts are in [`routines/`](../routines/); each one is a paste. Details and trigger settings in [scheduled-tasks.md](scheduled-tasks.md).

| Task | Trigger | Connectors |
|---|---|---|
| `worker-<repo>` | Schedule: hourly | Linear, Slack |
| `review-<repo>` | GitHub: Pull request opened / ready for review, Is draft = false | none |
| `release-<repo>` | GitHub: Pull request closed, Is merged = true | Linear, Slack |

Remove every other connector from each task. The task can use any connector you leave on, including writes.

## 6. Run the first ticket

Pick a trivial ticket (rename a constant, fix a typo in a message). Add `claude-ready`. Press **Run now** on the worker task. You should see, in order: a comment on the issue, a `claude/<KEY>-...` branch, a draft PR, a "Self-review round 1" comment, the PR flipping to ready, and `claude-pr-open` on the issue.

Then pick a deliberately vague ticket and confirm it ends in `claude-blocked` with a question, not in a bad PR.

## 7. Intake

In any Claude Code session on the repo:

```
/intake <notion-prd-url> <slack-thread-url> --team <KEY>
```

Tickets appear in Triage with `agent-drafted`. Promote the ones you want and add `claude-ready`.

## Adding another repository

Repeat steps 1, 2, 5. Everything else is per-team, not per-repo.
