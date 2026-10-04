# J2 patches on this fork

J2 Health's fork of [mattpocock/skills](https://github.com/mattpocock/skills), installed to J2 machines through the [j2-claude-plugins](https://github.com/j2-health/claude-plugins) marketplace (pinned by sha). Everything below differs from upstream on purpose. To update from upstream, follow [`.claude/skills/sync-upstream/SKILL.md`](.claude/skills/sync-upstream/SKILL.md) — **never** GitHub's "Sync fork → Discard commits", which deletes these patches.

## Model-invocable planning skills

| Skill | Upstream | Here |
|---|---|---|
| `wayfinder` | user-invoked | model-invoked |
| `to-spec` | user-invoked | model-invoked |
| `to-tickets` | user-invoked | model-invoked |
| `grill-with-docs` | user-invoked | model-invoked |

**Why:** `/j2-eng:claude-project-kickoff` sizes a body of work and hands it to the right planning flow inside a Claude Code Project thread. Upstream's user-invoked skills can only be fired by a human typing the slash command — no other skill can reach them (upstream `.agents/invocation.md`) — so the hand-off stalled on the user every step.

**What changed, per skill** (upstream's own convention for model-invoked skills, `.agents/invocation.md`):

- `SKILL.md` frontmatter: `disable-model-invocation: true` removed.
- `agents/openai.yaml`: the `policy` block with `allow_implicit_invocation: false` removed (keeps Codex in step).
- `description`: rewritten from a human-facing summary to model-facing "Use when…" triggers, deliberately narrow — `j2-eng` depends on this plugin, so these descriptions load into every J2 session.

Not changed: bucket `README.md` groupings, `docs/`, and `ask-matt` still describe these as user-invoked. Leaving upstream's prose alone keeps syncs conflict-free; the frontmatter is what the harness reads.

`scripts/j2-check-patches.sh` fails if any skill above regains the flags.

## J2-only files

Paths upstream doesn't use, so syncs never conflict on them: this file, `.claude/skills/sync-upstream/`, `scripts/j2-check-patches.sh`.
