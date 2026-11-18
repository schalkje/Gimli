# Workflow dependencies

The Claude workflows in `.github/workflows/` run code from outside this
repository: two GitHub Actions and the `code-review` plugin. Each is pinned, so
an upstream change cannot alter how pull requests are reviewed, or what the
review is allowed to do, without a reviewed pull request here. The cost is that
fixes upstream are not picked up automatically; every update is a deliberate
pull request through the lifecycle (`lifecycle.md`).

## What is pinned

| Dependency | Where | Pinned to |
|---|---|---|
| `actions/checkout` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `anthropics/claude-code-action` | `claude-code-review.yml`, `claude.yml` | Commit SHA, version in a trailing comment |
| `code-review` plugin | `vendor/claude-plugins/code-review/` | A verbatim copy of an upstream commit, recorded in `vendor/claude-plugins/README.md` |

The upstream plugin is not pinned by pinning a marketplace: the upstream
marketplace in `anthropics/claude-code` lists `code-review` as a `git-subdir`
source from `anthropics/claude-plugins-official` at `ref: main`.

## What the review loads

A pull request cannot change the plugin or the project configuration that
reviews it. Both come from the default branch:

- **The plugin.** The review workflow installs `code-review@gimli` from this
  repository's marketplace, `.claude-plugin/marketplace.json`. The action is
  given the marketplace as this repository's Git URL, built from the workflow
  context as `${{ github.server_url }}/${{ github.repository }}.git` so that
  it follows a rename or a copy of the repository, and clones its default
  branch. A local path (`./`), which the action also accepts, would read the
  plugin from the checkout.
- **The project configuration.** The workflow checks out the default branch,
  not the pull request, so the `CLAUDE.md` files, `.claude/` settings, hooks
  and skills, and `.mcp.json` that Claude Code loads are the ones on `main`.
  The review reads the change itself only through `gh pr diff` and
  `gh pr view`. This relies on the action not checking out the pull request
  in agent mode, which it uses for a `pull_request` event with a `prompt`: at
  the pinned version, only tag mode calls `setupBranch`
  (`src/github/operations/branch.ts`). Re-check this whenever the action pin
  moves.

The limits:

- A reviewer agent that opens a file on disk sees the `main` version, not the
  pull request's. Only the diff reflects the change.
- `CLAUDE.md` compliance is judged against the rules on `main`, so a pull
  request that changes `CLAUDE.md` is reviewed against the old rules.
- Whatever is on `main` reviews every open pull request. The `protect-main`
  ruleset admits changes to `main` only through a pull request, but admin
  credentials, including those Claude runs with, could change or remove the
  ruleset (`lifecycle.md`, Review).
- This covers the review workflow only. `claude.yml` acts for people with
  write access and works in the pull request's own checkout.

## Update an action pin

1. Resolve the tag to a commit SHA, and find the exact version that commit
   carries. `--paginate` matters: `claude-code-action` has more than 100 tags.

   ```sh
   gh api repos/actions/checkout/commits/v6 --jq .sha
   gh api --paginate "repos/actions/checkout/tags?per_page=100" --jq '.[] | select(.commit.sha == "<sha>") | .name'
   ```

   If no exact version tag points at that commit, pin the newest release
   instead: `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, then
   `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`. The trailing comment
   always names a tag that points at the pinned SHA.

   Use `anthropics/claude-code-action` and `v1` for the other action. For a
   new major version, read its release notes first; that is a change in what
   the workflow does, not only a pin.
2. Replace the SHA and the trailing version comment in **both** workflows, so
   they stay on the same version:

   ```yaml
   - uses: actions/checkout@<sha> # v6.1.0
   ```

3. Open a pull request. Record the `gh api` output in its evidence.

## Re-vendor the plugin

1. Find the upstream commit to take, usually the newest that touches the
   plugin:

   ```sh
   gh api "repos/anthropics/claude-plugins-official/commits?path=plugins/code-review&per_page=5" \
     --jq '.[] | .sha + " " + .commit.committer.date + " " + (.commit.message | split("\n")[0])'
   ```

2. Replace `vendor/claude-plugins/code-review/` with the upstream directory at
   that commit, on the pull request's branch. Fetch the commit and read its
   subtree straight into the index and working tree, so the bytes, file modes,
   symlinks, and removed files all match upstream:

   ```sh
   git fetch --depth 1 https://github.com/anthropics/claude-plugins-official.git <sha>
   git rm -r -q vendor/claude-plugins/code-review
   git read-tree --prefix=vendor/claude-plugins/code-review/ -u FETCH_HEAD:plugins/code-review
   ```

   Do not edit the copy.
3. Check it is identical (below), then update the commit, tree, version and
   date in `vendor/claude-plugins/README.md`.
4. Compare the `allowed-tools` frontmatter of
   `vendor/claude-plugins/code-review/commands/code-review.md` with the review
   workflow's `--allowedTools`. If upstream changed the list, decide whether to
   follow it; a widened list is a change in what the review may do and is
   assessed as such.
5. Open a pull request. It is reviewed with `/code-review <pr>`: the workflow
   still runs the plugin from `main`, so the new copy takes effect on the next
   pull request after the merge.

## Check the copy is identical

Equal Git tree hashes mean identical files, modes, and symlinks, on any
platform. `.gitattributes` marks `vendor/claude-plugins/code-review/**` as
`-text`, so Git never rewrites the vendored files' line endings.

```sh
git rev-parse HEAD:vendor/claude-plugins/code-review
gh api "repos/anthropics/claude-plugins-official/contents/plugins?ref=<sha>" \
  --jq '.[] | select(.name == "code-review") | .sha'
```

Before committing, `git write-tree --prefix=vendor/claude-plugins/code-review/`
gives the same hash for the staged copy.

Vendoring another plugin needs its own `vendor/claude-plugins/<name>/** -text`
line in `.gitattributes` before its files are added; otherwise Git may
normalise their line endings and the tree hash will not match upstream.

`claude plugin validate .` checks the marketplace and the plugin manifest.

## Changes to these files

The action only runs a workflow file identical to the copy on `main` (see
`lifecycle.md`, Review). A pull request that changes `claude-code-review.yml`
is therefore not reviewed by that workflow; review it with
`/code-review <pr>`. One that changes `claude.yml` still gets replies to
mentions in plain pull request comments, because GitHub runs `issue_comment`
workflows from `main`, but not to mentions in reviews or review comments,
which run the pull request's copy and are skipped. A pull request that
changes the vendored plugin is reviewed by the old copy. In every case,
check the first run after the merge.
