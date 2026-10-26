#!/bin/bash
# Fast-forward main to the filtered upstream history at a given sha, then rebase user-aliases.
# Usage: ./fork-sync.sh <upstream 40-char sha>   (the sha pinned in Hermes' plugin-catalog/hindsight.yaml)
set -euo pipefail
SHA=${1:?upstream sha}
[ ${#SHA} = 40 ] || { echo "need a full 40-char sha"; exit 1; }
REPO=$(git rev-parse --show-toplevel); cd "$REPO"
git diff --quiet && git diff --cached --quiet || { echo "working tree not clean"; exit 1; }
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
git clone -q --no-checkout https://github.com/vectorize-io/hindsight.git "$W/full"
git -C "$W/full" rev-parse --verify -q "$SHA^{commit}" >/dev/null || { echo "$SHA not in upstream"; exit 1; }
git clone -q --no-checkout --no-local "$W/full" "$W/filtered"
git -C "$W/filtered" remote remove origin
git -C "$W/filtered" checkout -q --detach "$SHA"
git -C "$W/filtered" for-each-ref --format='%(refname)' | xargs -r -n1 git -C "$W/filtered" update-ref -d
git -C "$W/filtered" filter-repo --quiet --path hindsight-integrations/hermes --path LICENSE \
  --path-rename hindsight-integrations/hermes/: --force --refs HEAD
NEW=$(git -C "$W/filtered" rev-parse HEAD)
git fetch -q "$W/filtered" HEAD
git merge-base --is-ancestor main "$NEW" || { echo "filtered history does not fast-forward main; filter changed?"; exit 1; }
git branch -f main "$NEW"
sed -i.bak -E "s|^  Current: [0-9a-f]{40}.*|  Current: $SHA|" FORK.md && rm FORK.md.bak
git rebase --onto main "$(git merge-base main user-aliases)" user-aliases
git add FORK.md && git commit -q -m "fork: upstream base $SHA" || true
echo "main -> $NEW; user-aliases rebased. Now run tests, tag, push."
