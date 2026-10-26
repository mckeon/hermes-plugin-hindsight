# Fork notes

Standalone copy of the Hermes memory-provider plugin from vectorize-io/hindsight
(`hindsight-integrations/hermes`). Upstream does not accept external PRs, so local changes
are carried as commits on top of upstream history.

- `main`: upstream history filtered to the plugin directory (moved to the root) plus
  LICENSE, produced by `git filter-repo`. Never commit to it by hand; it only ever
  fast-forwards to a new filter output.
- `user-aliases`: local commits rebased onto `main`. This is what gets installed.
- Upstream base is whatever the Hermes catalog pins:
  https://github.com/NousResearch/hermes-agent/blob/main/plugin-catalog/hindsight.yaml
  Current: d952b6e655fccab4581ee0722b51c5f103873d12 (plugin 1.2.3, 2026-10-15)
- License: MIT, unchanged (see LICENSE).

## Install

Pin an exact commit, never a branch:

    hermes plugins install mckeon/hermes-plugin-hindsight --ref <40-char sha> --force --enable

Tags `v<upstream version>-aliases.<n>` mark tested install points.

## Update when the catalog pin moves

    ./fork-sync.sh <new upstream sha>

That fetches upstream, re-runs the same filter (deterministic, so existing shas are
reproduced and `main` fast-forwards), and rebases `user-aliases` onto the new `main`.
Resolve conflicts if any, then:

    uv sync --frozen && uv run pytest tests -q
    git tag v<version>-aliases.1 && git push origin main user-aliases --tags --force-with-lease

Patches for upstream come straight from this tree:

    git format-patch main..user-aliases    # apply upstream with: git am --directory=hindsight-integrations/hermes
