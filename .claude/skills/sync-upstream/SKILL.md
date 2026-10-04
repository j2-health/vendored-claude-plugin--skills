---
name: sync-upstream
description: Use when updating this J2 fork (j2-health/vendored-claude-plugin--skills) to a newer mattpocock/skills release, when GitHub says the fork is behind upstream, when the mattpocock-skills pin in the j2-claude-plugins marketplace needs bumping, or before ever clicking GitHub's "Sync fork" button on this repo.
---

# Sync this fork with upstream

This repo is J2's fork of [mattpocock/skills](https://github.com/mattpocock/skills). It is **not** a clean mirror: it carries the J2 patch recorded in [`J2-PATCHES.md`](../../../J2-PATCHES.md). The j2-claude-plugins marketplace installs it pinned to a commit sha, so nothing reaches teammates until the pin is bumped.

**Never use GitHub's "Sync fork" → "Discard commits".** It resets `main` to upstream and silently deletes the J2 patch. "Update branch" (merge) is safe but skips the review and checks below, so use this skill instead.

## Steps

1. **Preflight.** Clean tree, on `main`, up to date with `origin`. Ensure the remote:
   ```sh
   git remote get-url upstream 2>/dev/null || git remote add upstream https://github.com/mattpocock/skills.git
   git fetch upstream --tags
   ```
2. **Pick the target: the latest release tag**, not upstream `main`, because the marketplace entry's `version` mirrors a released `package.json` version.
   ```sh
   TAG=$(git tag -l 'v*' --sort=-v:refname | head -1)
   git log --oneline main.."$TAG" | wc -l
   ```
   Already contained (`git merge-base --is-ancestor "$TAG" main`) → nothing to sync; stop.
3. **Review the upstream diff** before merging. The pin exists so third-party changes are reviewed. Summarize for the PR body:
   - `git diff --stat main..."$TAG" -- skills/ .claude-plugin/`: skills added, removed, renamed.
   - Every change to a **patched** skill (list in `J2-PATCHES.md`): read it in full.
   - Changes to `.agents/invocation.md` or any skill flipping **to** user-invoked that J2 calls: grep `~/workspace/j2-eng-plugin` for `mattpocock-skills` and the skill names. A newly user-invoked skill that J2 calls needs adding to the patch, or J2's caller breaks.
   - Renamed concepts J2 docs mention (e.g. `CONTEXT.md` → `GLOSSARY.md`).
4. **Merge on a branch**, never rebase: old pinned shas must stay reachable, and a merge keeps upstream's history intact for the next sync.
   ```sh
   git checkout -b "j2/sync-$TAG" main
   git merge --no-ff "$TAG" -m "Merge upstream $TAG"
   ```
5. **Conflicts** land only in patched skills (their `SKILL.md` frontmatter or `agents/openai.yaml`). Resolve by taking upstream's version of the file, then re-applying the patch from `J2-PATCHES.md`: drop the invocation flags, restore the J2 description (adjusted if upstream changed what the skill does).
6. **Verify.**
   ```sh
   bash scripts/j2-check-patches.sh
   jq -r .version package.json .claude-plugin/plugin.json   # both == ${TAG#v}
   claude plugin validate .
   ```
   Expect exactly one warning, upstream's own: "CLAUDE.md at the plugin root is not loaded". It fails `--strict` on pristine upstream too, so don't use `--strict` here.
7. **PR to this fork's `main`** with the step-3 summary. Merge it with **"Create a merge commit"**: squash or rebase-merge would cut the fork off from upstream's history and turn every future sync into a full-file conflict.
8. **Check the merge kept upstream's history**, since GitHub's default merge button may be squash:
   ```sh
   git fetch origin && git merge-base --is-ancestor "$TAG" origin/main && echo ancestry-ok
   ```
   If it fails, the PR was squash- or rebase-merged: the content is right but the next sync will merge from the old base and conflict. Restore it without rewriting history, in a PR that changes no files (merge that one with a merge commit too):
   ```sh
   git checkout -b j2/restore-ancestry-"$TAG" origin/main
   git merge -s ours "$TAG" -m "Record upstream $TAG as merged (restore ancestry)"
   ```
9. **Bump the pin** in `~/workspace/claude-plugins` (`j2-health/claude-plugins`): in `.claude-plugin/marketplace.json`, the `mattpocock-skills` entry's `source.sha` → the merge commit on this fork's `main` (full 40 hex), and `version` → `${TAG#v}`, **together**. Open that PR; its CI (`scripts/validate_manifests.py`) checks the shape.

## Changing the J2 patch without an upstream release

Edit the skills and `J2-PATCHES.md`, run step 6, PR, merge. Installed plugins are cached per version (`~/.claude/plugins/cache/<marketplace>/mattpocock-skills/<version>/`), so a new sha under the **same** version may never reach machines that already have it. Prefer shipping a patch-only change with the next upstream sync; if it can't wait, bump `PATCH` by one in `package.json` and `.claude-plugin/plugin.json`, note it in `J2-PATCHES.md`, and at the next sync pick a tag strictly greater than that version.
