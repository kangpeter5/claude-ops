# Scheduled task: release-<repo>

Trigger: GitHub event, Pull request → `pull_request.closed`, filter "Is merged" equals true. Repository: the target repo. Connectors: Linear, Slack.

Prompt (paste as-is):

---
A pull request was just merged in this repository. Find its number with `gh pr list --state merged --limit 5 --json number,title,mergedAt` and pick the one merged in the last 15 minutes whose title starts with a Linear key (e.g. `BE-123:`). If none matches, stop.

Run `/release <number>`. Follow it exactly: deploy checklist comment on the PR, release note on the Linear issue, issue to Done, Slack post to the originating thread or the release channel. Never trigger a deploy, workflow, or GitHub release.
---
