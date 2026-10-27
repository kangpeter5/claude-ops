# Contributing

Keep the engine generic. Anything that names a company, a team key, a reviewer or a hostname belongs in a consumer's `CLAUDE.md`, not here.

## Before opening a PR

```bash
claude plugin validate ./plugin
claude plugin validate .
bash -n scripts/install.sh plugin/hooks/guard.sh
echo '{"tool_input":{"command":"gh pr merge 1"}}' | plugin/hooks/guard.sh   # must print a deny
echo '{"tool_input":{"command":"gh pr ready 1"}}' | plugin/hooks/guard.sh   # must print nothing
```

Then run the installer against a scratch repo and start a local session there to confirm the skills appear under `/`.

## Conventions

- Skills carry `disable-model-invocation: true`. They run when a person or a scheduled-task prompt invokes them, never because Claude felt like it.
- Subagents declare `tools` allowlists. Add a tool only with a sentence in the PR explaining why.
- The guard hook's default patterns stay conservative. Project-specific commands go in `CLAUDE_OPS_DENY_PATTERNS`.
- Update `CHANGELOG.md` and bump `plugin/.claude-plugin/plugin.json` `version` in the same PR.
