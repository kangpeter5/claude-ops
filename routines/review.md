# Scheduled task: review-<repo>

Trigger: GitHub event, Pull request → `pull_request.opened` and `pull_request.ready_for_review`, filter "Is draft" equals false. Repository: the target repo. Connectors: none.

Prompt (paste as-is):

---
A pull request was just opened or marked ready for review in this repository. The checkout is at the PR's head commit.

1. Find the PR with `gh pr list --head "$(git branch --show-current)" --json number,title,body,isDraft` (or from the event context if present). If it is a draft, stop.
2. Delegate the review to the `reviewer` subagent with the PR number, the base branch, and the acceptance criteria from the PR body. It returns JSON findings.
3. Post each finding as an inline review comment on the exact file and line with `gh api repos/{owner}/{repo}/pulls/{n}/reviews` (event COMMENT, never APPROVE or REQUEST_CHANGES). Prefix each comment with its severity. Add one summary comment: counts by severity, the test command and result, and "Human review still required."
4. Do not push commits, do not resolve threads, do not change labels. Stop.
---
