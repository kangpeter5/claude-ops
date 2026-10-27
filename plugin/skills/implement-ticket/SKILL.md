---
name: implement-ticket
description: Implement one Linear issue end to end on a claude/<KEY>-slug branch, open a draft PR, run the self-review loop with a fresh reviewer until clean (max 3 rounds), then mark the PR ready and label the issue claude-pr-open. Blocks with claude-blocked when it needs a human decision.
argument-hint: "<LINEAR-KEY>"
disable-model-invocation: true
allowed-tools: Agent, Read, Edit, Write, Grep, Glob, Bash, mcp__Linear__*
effort: high
---

# /implement-ticket

Issue: `$0` (a Linear identifier like `BE-123`). Required.

Read the repository `CLAUDE.md` first. It holds the build, test and lint commands, the branch convention, the sensitive paths, and the Linear team. Everything below assumes you follow it.

## Phase 1: Understand

1. Fetch the issue, its comments, its parent/children and blocking relations, and any attached PRD link.
2. If the issue is blocked by an open "Decisions needed" issue or any unresolved blocker, set label `claude-blocked`, comment which blocker, and stop.
3. Restate the acceptance criteria as a checklist in your own words. If any criterion is untestable or contradicts the codebase, do not guess: set `claude-blocked`, comment the specific question with two options, and stop.
4. Locate the code. Grep for the affected area named in the issue. Read neighbors and tests. Note the existing patterns you will follow.

## Phase 2: Implement

5. Branch from the default branch: `git checkout -b claude/<KEY>-<slug>` where slug is 3-5 lowercase words from the title.
6. Implement the smallest change that meets every acceptance criterion. Reuse existing helpers; do not add a dependency unless the issue asks for it.
7. Add or update tests so each acceptance criterion has at least one test. Run the full test command from `CLAUDE.md`, then lint. Fix until green.
8. Commit in logical steps with messages prefixed `<KEY>: `. Push with `git push -u origin <branch>`.

## Phase 3: Draft PR

9. Open a **draft** PR with `gh pr create --draft`:
   - Title: `<KEY>: <issue title>`
   - Body: the acceptance-criteria checklist with each box ticked and the test that proves it, a "How to verify" section, and `Closes <issue URL>` plus the Linear magic word for the key (e.g. `Fixes <KEY>`).
10. Attach the PR URL to the Linear issue (attachment or comment) and comment "Draft PR open, starting self-review."

## Phase 4: Self-review loop

Round N starts at 1. Hard cap: 3.

11. Delegate to the `reviewer` subagent (`delivery-loop:reviewer` as a plugin) with: the PR number, the base branch, and the issue's acceptance criteria verbatim. Nothing about your reasoning or what you think is fine. It returns JSON.
12. If `verdict` is `clean`: go to Phase 5.
13. Otherwise delegate to the `pr-responder` subagent (`delivery-loop:pr-responder` as a plugin) with the findings JSON and the round number. It fixes, tests, commits `<KEY>: address self-review round N`, pushes, and returns JSON.
14. Post a PR comment:

    ```
    ### Self-review round N
    Findings: <count> (<high>/<medium>/<low>)
    - [fixed] <file>: <summary>
    - [won't fix] <file>: <summary> — <reason>
    Commit: <sha>
    ```

15. If `pr-responder` returned anything under `blocked`: set `claude-blocked` on the issue, comment the questions, leave the PR as draft, and stop.
16. If N < 3: N += 1, go to step 11. If N = 3 and the last review still had `high` findings: set `claude-blocked`, comment the unresolved high findings on the issue, leave the PR as draft, stop. If only `medium`/`low` remain: post them as a PR comment titled "Known leftovers from self-review" and continue.

## Phase 5: Hand to humans

17. `gh pr ready <number>`. Request reviewers from CODEOWNERS or the reviewers named in `CLAUDE.md`.
18. On the Linear issue: remove `claude-in-progress`, add `claude-pr-open`, comment "PR ready for review: <url>. Self-review rounds: N."
19. Stop. Do not merge, do not deploy, do not resolve anything.

## Budget

If you are past roughly 150 tool calls and not in Phase 4, stop, push what you have, set `claude-blocked` with a comment explaining where you got to, and leave the PR as draft.
