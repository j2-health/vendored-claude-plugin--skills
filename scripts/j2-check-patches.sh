#!/usr/bin/env bash
# Fails if a skill J2 patched to be model-invoked (see J2-PATCHES.md) has
# regained upstream's user-invoked flags, typically after an upstream sync.
set -eu

cd "$(dirname "$0")/.."

PATCHED="wayfinder to-spec to-tickets grill-with-docs"
fail=0

for name in $PATCHED; do
  dir=$(find skills/engineering skills/productivity -type d -name "$name" 2>/dev/null | head -1)
  if [ -z "$dir" ]; then
    echo "FAIL $name: skill directory not found (renamed or moved upstream?)"
    fail=1
    continue
  fi
  if grep -q '^disable-model-invocation:' "$dir/SKILL.md"; then
    echo "FAIL $name: $dir/SKILL.md sets disable-model-invocation"
    fail=1
  fi
  if [ -f "$dir/agents/openai.yaml" ] && grep -q 'allow_implicit_invocation: *false' "$dir/agents/openai.yaml"; then
    echo "FAIL $name: $dir/agents/openai.yaml sets allow_implicit_invocation: false"
    fail=1
  fi
  if ! grep -Eq '^description: "?Use when' "$dir/SKILL.md"; then
    echo "FAIL $name: $dir/SKILL.md description is not model-facing (expected 'Use when…')"
    fail=1
  fi
done

[ "$fail" -eq 0 ] && echo "OK: J2 patches intact ($PATCHED)"
exit "$fail"
