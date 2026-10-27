# Scheduled tasks

Create them at [claude.ai/code/routines](https://claude.ai/code/routines) or with `/schedule` in a session. Official reference: [Automate work with scheduled tasks](https://code.claude.com/docs/en/routines).

## worker-\<repo\>

- **Trigger**: Schedule, hourly. Add **Run now** when you want to test.
- **Repository**: the target repo. One worker per repo. If one repo serves two Linear teams, create one worker per team with different `TEAM` values.
- **Connectors**: Linear, Slack. Remove the rest.
- **Prompt**: [`routines/worker.md`](../routines/worker.md). Replace `TEAM`.
- **What a run does**: `/next-ticket` → claim → `/implement-ticket` → draft PR → self-review loop → `gh pr ready` → `claude-pr-open`. Or exits in seconds when there is nothing `claude-ready`.

## review-\<repo\>

- **Trigger**: GitHub event, **Pull request**, actions `opened` and `ready_for_review`. Filter **Is draft** equals `false`. Optionally filter **Head branch** starts with `claude/` while you build trust, then remove the filter to review every PR.
- **Repository**: the target repo. The checkout starts at the PR head commit when the PR's repo is the task's first repository.
- **Connectors**: none.
- **Prompt**: [`routines/review.md`](../routines/review.md).
- **What a run does**: fresh `reviewer` subagent on the diff, inline comments by severity, one summary. Never approves, never requests changes, never pushes.

## release-\<repo\>

- **Trigger**: GitHub event, **Pull request**, action `closed`. Filter **Is merged** equals `true`.
- **Repository**: the target repo.
- **Connectors**: Linear, Slack.
- **Prompt**: [`routines/release.md`](../routines/release.md).
- **What a run does**: `/release` → deploy checklist comment, release note, Linear Done, Slack post. Never deploys.

## Limits that shape the setup

From the docs at the time of writing; the feature is in research preview and these can change.

- Schedules more frequent than hourly are rejected.
- GitHub webhook events have per-task and per-account hourly caps; events beyond the cap are dropped.
- Runs count against the owner's usage.
- If the owner's GitHub connection expires, the task skips runs for up to 72 hours, then turns off.

## Permissions during a run

A run starts in auto mode: a classifier allows or blocks actions that would otherwise wait for you. The deny rules in `.claude/settings.json` still apply and still win. A run can stop and wait for an answer; check the task's run list if a ticket sits in `claude-in-progress` for more than an hour.

## Pausing

- One ticket: remove `claude-ready`. If it is already `claude-in-progress`, also delete the `claude/<KEY>-*` branch or the next run will skip it with a comment.
- Everything: open the task and toggle it off.
